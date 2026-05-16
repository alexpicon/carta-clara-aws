"""KODA-05 — smoke tests for POST /scan.

Exercises the scan handler end-to-end with mocked AWS clients:
  - happy path: image -> extraction -> Spanish summary -> audio -> assembled response
  - validation: missing image, oversized, unsupported format
  - Guardrail refusal path: intervention -> refusal-case response shape
"""

import json
from unittest.mock import MagicMock

from conftest import TEST_PNG_B64, converse_response, make_polly, make_s3


def _event(body):
    return {"body": json.dumps(body), "requestContext": {"http": {"method": "POST"}}}


def _seed(helpers, bedrock=None, s3=None, polly=None):
    helpers.reset_clients()
    helpers._CLIENTS["bedrock-runtime"] = bedrock or MagicMock()
    helpers._CLIENTS["s3"] = s3 or make_s3()
    helpers._CLIENTS["polly"] = polly or make_polly()


_EXTRACTION_JSON = json.dumps(
    {
        "document_type": "Notice to Appear (Form I-862)",
        "issuing_agency": "U.S. Department of Justice — EOIR",
        "country_of_origin": "Mexico",
        "country_of_citizenship": "Mexico",
        "hearing_date": "2026-10-15",
        "hearing_time": "09:00",
        "court_name": "Seattle Immigration Court",
        "court_address": "1000 Second Avenue, Suite 2900, Seattle, WA 98104",
        "issuing_officer": "Officer J. Sample",
        "alleged_basis_summary": "Overstay of B-2 nonimmigrant admission",
        "charges_cited": ["INA section 237(a)(1)(B)"],
        "deadline_critical": "2026-10-15",
        "is_demo_document": True,
        "demo_watermark_detected": True,
    }
)

_SUMMARY_JSON = json.dumps(
    {
        "summary_en": "A notice to appear in immigration court on October 15, 2026.",
        "summary_es": "Es un aviso para presentarte en la corte de inmigracion el "
        "15 de octubre. No es una orden final. Pide ayuda legal gratis.",
        "sections": [
            {
                "section_title_en": "Why you received this",
                "section_title_es": "Por que recibiste esto",
                "section_body_es": "El gobierno dice que te quedaste mas tiempo.",
                "section_body_full_es": "El gobierno dice que te quedaste en EE.UU. "
                "mas tiempo del permitido por tu visa B-2.",
                "citation_ids": ["kb-eoir-nta-1"],
            }
        ],
    }
)


def test_scan_happy_path(load_handler):
    handler, helpers = load_handler("scan")
    bedrock = MagicMock()
    bedrock.converse.side_effect = [
        converse_response(_EXTRACTION_JSON),
        converse_response(_SUMMARY_JSON),
    ]
    _seed(helpers, bedrock=bedrock)

    resp = handler.lambda_handler(_event({"image_base64": TEST_PNG_B64}), None)
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])

    # contract-shaped response
    assert body["session_id"] and body["document_id"]
    assert body["extraction"]["document_type"] == "Notice to Appear (Form I-862)"
    # PII flags are always true — Guardrail masks before the model sees the doc
    assert body["extraction"]["names_redacted"] is True
    assert body["extraction"]["a_number_redacted"] is True
    assert body["extraction"]["is_demo_document"] is True
    assert body["summary_es"].startswith("Es un aviso")
    assert body["audio_url"].startswith("https://")
    assert body["urgency"]["is_urgent"] is True
    assert body["urgency"]["deadline_date"] == "2026-10-15"
    assert body["court_brief"]["court_name"] == "Seattle Immigration Court"
    assert len(body["legal_aid_options"]) == 3
    assert body["sections"][0]["citation_ids"] == ["kb-eoir-nta-1"]
    assert body["citations"][0]["id"] == "kb-eoir-nta-1"
    assert body["latency_ms"] >= 0
    assert body["cost_estimate_usd"] >= 0

    # Guardrail attached on BOTH Bedrock calls (TENETS §8)
    assert bedrock.converse.call_count == 2
    for call in bedrock.converse.call_args_list:
        assert "guardrailConfig" in call.kwargs
        assert call.kwargs["guardrailConfig"]["guardrailIdentifier"] == "test-guardrail-id"


def test_scan_missing_image(load_handler):
    handler, helpers = load_handler("scan")
    _seed(helpers)
    resp = handler.lambda_handler(_event({}), None)
    assert resp["statusCode"] == 400
    assert "image_base64" in json.loads(resp["body"])["error"]


def test_scan_unsupported_format(load_handler):
    handler, helpers = load_handler("scan")
    _seed(helpers)
    import base64

    not_an_image = base64.b64encode(b"%PDF-1.7 this is a pdf").decode()
    resp = handler.lambda_handler(_event({"image_base64": not_an_image}), None)
    assert resp["statusCode"] == 415
    assert "JPEG or PNG" in json.loads(resp["body"])["error"]


def test_scan_oversized_image(load_handler):
    handler, helpers = load_handler("scan")
    _seed(helpers)
    import base64

    huge = base64.b64encode(b"\xff\xd8\xff" + b"0" * (10 * 1024 * 1024 + 1)).decode()
    resp = handler.lambda_handler(_event({"image_base64": huge}), None)
    assert resp["statusCode"] == 400


def test_scan_guardrail_refusal(load_handler):
    """A Guardrail intervention on the document -> refusal-case response (still 200)."""
    handler, helpers = load_handler("scan")
    bedrock = MagicMock()
    bedrock.converse.return_value = converse_response(
        "blocked", stop_reason="guardrail_intervened", blocked_topic="DocumentAuthenticity"
    )
    _seed(helpers, bedrock=bedrock)

    resp = handler.lambda_handler(_event({"image_base64": TEST_PNG_B64}), None)
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])
    assert body["was_refused"] is True
    assert body["refusal_reason"]
    assert body["refusal_text_es"]
    assert len(body["legal_aid_options"]) == 3


def test_scan_extraction_unparseable(load_handler):
    """Model returns no JSON -> 422 could not extract structured data."""
    handler, helpers = load_handler("scan")
    bedrock = MagicMock()
    bedrock.converse.return_value = converse_response("sorry, no idea")
    _seed(helpers, bedrock=bedrock)

    resp = handler.lambda_handler(_event({"image_base64": TEST_PNG_B64}), None)
    assert resp["statusCode"] == 422
