"""Smoke tests for POST /scan/packet.

Exercises the scan_packet handler with mocked AWS clients:
  - happy path: document -> Bedrock packet -> assembled API_CONTRACT response
  - validation: missing session_id / document_id -> 400
  - 404: document_id expired / not found
  - Guardrail intervention -> safe routing packet (still 200, no doc claims)
"""

import json
from unittest.mock import MagicMock

from conftest import converse_response, make_s3

SESSION = "44444444-4444-4444-8444-444444444444"
DOCUMENT = "55555555-5555-4555-8555-555555555555"

_PACKET_JSON = json.dumps(
    {
        "title_es": "Paquete de preparación para tu cita legal",
        "what_this_says_es": "Tu documento es un aviso para presentarte en la corte "
        "de inmigración el 15 de octubre de 2026. No es una orden final.",
        "your_deadline": {
            "date": "2026-10-15",
            "label_es": "Fecha de corte: 15 de octubre de 2026, 9:00 AM",
        },
        "documents_to_gather_es": [
            "Tu pasaporte o identificación consular",
            "Cualquier papel de inmigración anterior",
        ],
        "extension_request_template": "## Solicitud para reprogramar\n\n_Solo si "
        "tienes un conflicto documentado._ Tu abogado escribe la respuesta oficial.",
        "legal_aid_phone_script_es": "Hola, recibí un Notice to Appear...",
        "questions_for_lawyer_es": [
            "¿Qué significa esta acusación en mi caso?",
            "¿Qué evidencia debería juntar?",
        ],
        "cover_sheet_es": "Lleva este paquete a tu cita con ayuda legal gratis.",
    }
)


def _event(body):
    return {"body": json.dumps(body), "requestContext": {"http": {"method": "POST"}}}


def _seed(helpers, bedrock=None, s3=None):
    helpers.reset_clients()
    helpers._CLIENTS["bedrock-runtime"] = bedrock or MagicMock()
    helpers._CLIENTS["s3"] = s3 or make_s3()


def test_scan_packet_happy_path(load_handler):
    handler, helpers = load_handler("scan_packet")
    bedrock = MagicMock()
    bedrock.converse.return_value = converse_response(_PACKET_JSON)
    _seed(helpers, bedrock=bedrock)

    resp = handler.lambda_handler(
        _event({"session_id": SESSION, "document_id": DOCUMENT}), None
    )
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])

    assert body["session_id"] == SESSION
    packet = body["packet"]
    # every API_CONTRACT packet field present
    for field in (
        "title_es",
        "what_this_says_es",
        "your_deadline",
        "documents_to_gather_es",
        "extension_request_template",
        "legal_aid_phone_script_es",
        "questions_for_lawyer_es",
        "cover_sheet_es",
    ):
        assert field in packet, f"missing packet field: {field}"
    assert packet["your_deadline"]["date"] == "2026-10-15"
    assert len(packet["documents_to_gather_es"]) == 2
    assert len(packet["questions_for_lawyer_es"]) == 2
    assert body["pdf_url"] is None  # v1 — iOS renders Markdown locally
    assert len(body["legal_aid_options"]) == 3

    # Guardrail attached (TENETS §8)
    assert "guardrailConfig" in bedrock.converse.call_args.kwargs


def test_scan_packet_missing_ids(load_handler):
    handler, helpers = load_handler("scan_packet")
    _seed(helpers)
    resp = handler.lambda_handler(_event({"session_id": SESSION}), None)
    assert resp["statusCode"] == 400


def test_scan_packet_document_expired(load_handler):
    handler, helpers = load_handler("scan_packet")
    _seed(helpers, s3=make_s3(found=False))
    resp = handler.lambda_handler(
        _event({"session_id": SESSION, "document_id": DOCUMENT}), None
    )
    assert resp["statusCode"] == 404


def test_scan_packet_guardrail_intervention(load_handler):
    """A Guardrail intervention -> safe routing packet, no document-derived claims."""
    handler, helpers = load_handler("scan_packet")
    bedrock = MagicMock()
    bedrock.converse.return_value = converse_response(
        "blocked", stop_reason="guardrail_intervened", blocked_topic="LegalStrategy"
    )
    _seed(helpers, bedrock=bedrock)

    resp = handler.lambda_handler(
        _event({"session_id": SESSION, "document_id": DOCUMENT}), None
    )
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])
    # contract shape intact even on the safe path
    assert body["packet"]["cover_sheet_es"]
    assert body["packet"]["questions_for_lawyer_es"]
    assert "ayuda legal gratis" in body["packet"]["what_this_says_es"]
    assert len(body["legal_aid_options"]) == 3
