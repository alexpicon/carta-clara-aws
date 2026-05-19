"""Smoke tests for POST /ask.

Exercises the ask handler with mocked AWS clients:
  - happy path: text question -> grounded Spanish answer + citations
  - validation: missing ids, both/neither question and audio
  - 404: document_id expired / not found
  - adversarial prompt -> Guardrail refusal -> DynamoDB refusal-log entry written
    with the expected shape {session_id, ts, question_hash, reason, ttl}.
"""

import json
import time
from unittest.mock import MagicMock

from conftest import converse_response, make_dynamodb, make_polly, make_s3

SESSION = "11111111-1111-4111-8111-111111111111"
DOCUMENT = "22222222-2222-4222-8222-222222222222"


def _event(body):
    return {"body": json.dumps(body), "requestContext": {"http": {"method": "POST"}}}


def _seed(helpers, bedrock=None, s3=None, polly=None, dynamodb=None):
    helpers.reset_clients()
    helpers._CLIENTS["bedrock-runtime"] = bedrock or MagicMock()
    helpers._CLIENTS["s3"] = s3 or make_s3()
    helpers._CLIENTS["polly"] = polly or make_polly()
    helpers._CLIENTS["resource:dynamodb"] = dynamodb or make_dynamodb()


def test_ask_happy_path(load_handler):
    handler, helpers = load_handler("ask")
    bedrock = MagicMock()
    bedrock.converse.return_value = converse_response(
        json.dumps(
            {
                "answer_es": "Tu documento dice que tienes una audiencia el 15 de "
                "octubre de 2026. Esto es informacion, no consejo legal.",
                "citation_ids": [],
            }
        )
    )
    _seed(helpers, bedrock=bedrock)

    resp = handler.lambda_handler(
        _event(
            {
                "session_id": SESSION,
                "document_id": DOCUMENT,
                "question": "Que dice mi documento?",
            }
        ),
        None,
    )
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])
    assert body["was_refused"] is False
    assert body["refusal_reason"] is None
    assert "audiencia" in body["answer_es"]
    assert body["answer_audio_url"].startswith("https://")
    assert len(body["legal_aid_options"]) == 3

    # Guardrail attached (TENETS §8)
    assert "guardrailConfig" in bedrock.converse.call_args.kwargs


def test_ask_missing_ids(load_handler):
    handler, helpers = load_handler("ask")
    _seed(helpers)
    resp = handler.lambda_handler(_event({"question": "hola"}), None)
    assert resp["statusCode"] == 400


def test_ask_both_question_and_audio(load_handler):
    handler, helpers = load_handler("ask")
    _seed(helpers)
    resp = handler.lambda_handler(
        _event(
            {
                "session_id": SESSION,
                "document_id": DOCUMENT,
                "question": "hola",
                "audio_base64": "AAAA",
                "audio_format": "wav",
            }
        ),
        None,
    )
    assert resp["statusCode"] == 400


def test_ask_neither_question_nor_audio(load_handler):
    handler, helpers = load_handler("ask")
    _seed(helpers)
    resp = handler.lambda_handler(
        _event({"session_id": SESSION, "document_id": DOCUMENT}), None
    )
    assert resp["statusCode"] == 400


def test_ask_document_expired(load_handler):
    """An expired/unknown document_id -> 404 (S3 1h lifecycle)."""
    handler, helpers = load_handler("ask")
    _seed(helpers, s3=make_s3(found=False))
    resp = handler.lambda_handler(
        _event(
            {"session_id": SESSION, "document_id": DOCUMENT, "question": "hola"}
        ),
        None,
    )
    assert resp["statusCode"] == 404


def test_ask_adversarial_guardrail_refusal(load_handler):
    """Adversarial legal-strategy prompt -> Guardrail refusal + DynamoDB log entry.

    Verifies the refusal-log row shape required by API_CONTRACT:
    {session_id, ts, question_hash, reason, ttl}.
    """
    handler, helpers = load_handler("ask")
    bedrock = MagicMock()
    bedrock.converse.return_value = converse_response(
        "No puedo ayudarte con estrategia legal.",
        stop_reason="guardrail_intervened",
        blocked_topic="LegalStrategy",
    )
    dynamodb = make_dynamodb()
    _seed(helpers, bedrock=bedrock, dynamodb=dynamodb)

    before = int(time.time())
    resp = handler.lambda_handler(
        _event(
            {
                "session_id": SESSION,
                "document_id": DOCUMENT,
                "question": "Que deberia decirle al juez para ganar mi caso?",
            }
        ),
        None,
    )
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])
    assert body["was_refused"] is True
    assert body["refusal_reason"] == "legal_strategy"
    assert body["refusal_text_es"]
    assert body["answer_es"] is None
    assert len(body["legal_aid_options"]) == 3

    # a PII-redacted refusal row was written to DynamoDB
    dynamodb._table.put_item.assert_called_once()
    item = dynamodb._table.put_item.call_args.kwargs["Item"]
    assert item["session_id"] == SESSION
    assert item["reason"] == "legal_strategy"
    assert "ts" in item
    # question stored only as a short hash — never verbatim (TENETS §7)
    assert len(item["question_hash"]) == 16
    assert "juez" not in item["question_hash"]
    assert before + 3600 <= item["ttl"] <= before + 3601 + 5


def test_ask_prompt_layer_refusal(load_handler):
    """Layer-2 fallback (defense in depth): with NO Guardrail interception, a
    model-reported refusal JSON still drives the refusal path + DynamoDB log.

    This is the case that matters while GUARDRAIL_ID is still 'PLACEHOLDER' —
    the refusal counter must still tick. The fake Converse response has
    stop_reason='end_turn' and no blocked_topic, so res.intervened is False
    and only the prompt layer can catch the refusal.
    """
    handler, helpers = load_handler("ask")
    bedrock = MagicMock()
    bedrock.converse.return_value = converse_response(
        json.dumps(
            {
                "refused": True,
                "refusal_reason": "hearing_attendance",
                "refusal_text_es": "No puedo aconsejarte si debes ir a la "
                "audiencia; esa decision la toma un abogado. Si puedo "
                "explicarte el documento y darte preguntas para ayuda legal "
                "gratuita.",
            }
        )
    )
    dynamodb = make_dynamodb()
    _seed(helpers, bedrock=bedrock, dynamodb=dynamodb)

    resp = handler.lambda_handler(
        _event(
            {
                "session_id": SESSION,
                "document_id": DOCUMENT,
                "question": "Debo faltar a mi audiencia?",
            }
        ),
        None,
    )
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])
    assert body["was_refused"] is True
    assert body["refusal_reason"] == "hearing_attendance"
    assert body["refusal_text_es"]
    assert body["answer_es"] is None
    # the refusal was logged even though the Guardrail never intervened
    dynamodb._table.put_item.assert_called_once()
    assert dynamodb._table.put_item.call_args.kwargs["Item"]["reason"] == (
        "hearing_attendance"
    )


def test_ask_prompt_refusal_unknown_reason_coerced(load_handler):
    """A model-reported refusal with an unrecognized reason coerces to 'other'."""
    handler, helpers = load_handler("ask")
    bedrock = MagicMock()
    bedrock.converse.return_value = converse_response(
        json.dumps(
            {
                "refused": True,
                "refusal_reason": "not_a_real_enum",
                "refusal_text_es": "No puedo ayudarte con eso, pero un "
                "servicio de ayuda legal gratuito si puede.",
            }
        )
    )
    _seed(helpers, bedrock=bedrock)

    resp = handler.lambda_handler(
        _event(
            {
                "session_id": SESSION,
                "document_id": DOCUMENT,
                "question": "Pregunta fuera de alcance.",
            }
        ),
        None,
    )
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])
    assert body["was_refused"] is True
    assert body["refusal_reason"] == "other"
