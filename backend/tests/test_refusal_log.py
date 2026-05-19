"""Smoke tests for GET /refusal-log.

Verifies the DynamoDB query returns the correct count and recent entries, and
that each entry carries the required `topic_label_es` field.
"""

import json

from conftest import make_dynamodb


def _event(session_id=None):
    qs = {"session_id": session_id} if session_id is not None else None
    return {"queryStringParameters": qs, "requestContext": {"http": {"method": "GET"}}}


SESSION = "33333333-3333-4333-8333-333333333333"

_ITEMS = [
    {"session_id": SESSION, "ts": "2026-05-16T03:10:00Z", "reason": "legal_strategy",
     "question_hash": "abcd1234abcd1234"},
    {"session_id": SESSION, "ts": "2026-05-16T03:05:00Z", "reason": "outcome",
     "question_hash": "ef567890ef567890"},
    {"session_id": SESSION, "ts": "2026-05-16T03:01:00Z", "reason": "evasion",
     "question_hash": "11112222333344445"[:16]},
]


def test_refusal_log_count_and_entries(load_handler):
    handler, helpers = load_handler("refusal_log")
    dynamodb = make_dynamodb(items=_ITEMS)
    helpers.reset_clients()
    helpers._CLIENTS["resource:dynamodb"] = dynamodb

    resp = handler.lambda_handler(_event(SESSION), None)
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])

    assert body["session_id"] == SESSION
    assert body["count"] == 3
    assert len(body["refusals"]) == 3

    first = body["refusals"][0]
    assert first["reason"] == "legal_strategy"
    assert first["ts"] == "2026-05-16T03:10:00Z"
    # Spanish topic label present for the iOS refusal-log UI
    assert first["topic_label_es"] == "Estrategia legal"
    # never leak the question hash to the client
    assert "question_hash" not in first

    # the query asked for newest-first, capped at 20
    query_kwargs = dynamodb._table.query.call_args.kwargs
    assert query_kwargs["ScanIndexForward"] is False
    assert query_kwargs["Limit"] == 20


def test_refusal_log_empty_session(load_handler):
    handler, helpers = load_handler("refusal_log")
    dynamodb = make_dynamodb(items=[])
    helpers.reset_clients()
    helpers._CLIENTS["resource:dynamodb"] = dynamodb

    resp = handler.lambda_handler(_event("unknown-session"), None)
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])
    assert body["count"] == 0
    assert body["refusals"] == []


def test_refusal_log_missing_session_id(load_handler):
    handler, helpers = load_handler("refusal_log")
    helpers.reset_clients()
    resp = handler.lambda_handler(_event(None), None)
    assert resp["statusCode"] == 400
    assert "session_id" in json.loads(resp["body"])["error"]


def test_refusal_log_unknown_reason_falls_back(load_handler):
    """An item with a reason not in the taxonomy still gets a Spanish label."""
    handler, helpers = load_handler("refusal_log")
    dynamodb = make_dynamodb(
        items=[{"session_id": SESSION, "ts": "2026-05-16T03:00:00Z", "reason": "weird"}]
    )
    helpers.reset_clients()
    helpers._CLIENTS["resource:dynamodb"] = dynamodb

    resp = handler.lambda_handler(_event(SESSION), None)
    body = json.loads(resp["body"])
    assert body["refusals"][0]["topic_label_es"]  # falls back to the 'other' label
