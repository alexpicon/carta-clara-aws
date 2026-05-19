"""GET /refusal-log?session_id=<id> — Carta Clara visible trust counter.

Returns the count and the 20 most recent refusals for a session, sorted newest
first. The iOS floating refusal counter polls this — TENETS §1 (trust before
features): a visible, growing refusal count is the product's strongest trust
signal.

Notes:
  - DynamoDB Query: KeyConditionExpression on the partition key `session_id`,
    ScanIndexForward=False (newest first), Limit=20.
  - The response includes `topic_label_es`, which API_CONTRACT.md
    (§ GET /refusal-log) requires for each refusal so the iOS refusal-log UI can
    show a human-readable Spanish topic label (added via helpers.reason_label_es).
  - Hardened: never echo `question_hash` (kept server-side only); tolerate items
    written before `reason` existed.
"""

import json

from boto3.dynamodb.conditions import Key

import helpers as h


def lambda_handler(event, _context):
    """Entry point for GET /refusal-log."""
    qs = event.get("queryStringParameters") or {}
    session_id = qs.get("session_id")

    if not session_id:
        return h.response(400, {"error": "session_id query param required"})

    try:
        table = h.resource("dynamodb").Table(h.env("REFUSAL_TABLE"))
        result = table.query(
            KeyConditionExpression=Key("session_id").eq(session_id),
            ScanIndexForward=False,  # newest first
            Limit=20,
        )
        items = result.get("Items", [])
        refusals = []
        for item in items:
            reason = item.get("reason", "other")
            refusals.append(
                {
                    "ts": item.get("ts"),
                    "reason": reason,
                    "topic_label_es": h.reason_label_es(reason),
                }
            )
        return h.response(
            200,
            {
                "session_id": session_id,
                "count": len(refusals),
                "refusals": refusals,
            },
        )
    except Exception as exc:  # noqa: BLE001
        print(json.dumps({"level": "error", "msg": "refusal_log_query_failed",
                          "error": str(exc)}))
        return h.response(500, {"error": "internal error"})
