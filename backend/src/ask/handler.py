"""POST /ask — Carta Clara bounded follow-up chat.

Flow (API_CONTRACT.md § POST /ask):
  1. Validate: session_id + document_id required; exactly one of question / audio.
  2. If audio: transcribe to text (AWS Transcribe).
  3. Fetch the scanned document image from S3 for grounding (404 if expired).
  4. Retrieve grounding chunks from the Bedrock Knowledge Base.
  5. Bedrock Converse (Guardrail attached) with the document + question + KB context.
  6. Refusal — resolved from TWO layers (defense in depth, h.resolve_refusal):
     the Bedrock Guardrail intervening, OR the model self-reporting a refusal
     in its JSON output. Either way: log a PII-redacted refusal to DynamoDB and
     return the safe-replacement text + escalation card (TENETS §2). The prompt
     layer keeps refusals working even while the Guardrail is unconfigured.
  7. Otherwise: return the Spanish answer + citations.

Refusal log entry: {session_id, ts, question_hash, reason, ttl: now+3600}.
We never store the question verbatim — only a short SHA-256 hash (TENETS §7).

Transcription note: AWS Transcribe *streaming* needs the async `amazon-transcribe`
SDK. Koda's iron rule is boto3-only, so this uses Transcribe batch jobs with a
bounded poll. Short voice clips finish well inside the Lambda timeout; if a job
runs long the handler degrades to asking the user to type.
"""

import base64
import binascii
import hashlib
import json
import time
import urllib.request
import uuid

import helpers as h

TRANSCRIBE_POLL_SECONDS = 22  # bounded so we stay inside the Lambda timeout
AUDIO_FORMATS = ("wav", "mp3", "webm", "ogg", "flac", "amr")

_FALLBACK_ASK = (
    "You answer a follow-up question about the user's own immigration document, "
    "in plain Spanish. You give INFORMATION, never legal advice (TENETS §3): you "
    "may explain what the document says, identify dates, and suggest questions for "
    "a lawyer. Ground every claim in the document or the provided knowledge-base "
    "context. If you cannot verify an answer, say so and route the user to free "
    "legal aid.\n\n"
    "REFUSAL RULE — you MUST refuse, and must NOT answer, if the question asks "
    "for any of: legal strategy; whether to attend or skip a hearing; whether to "
    "admit or deny allegations; a prediction of eligibility or case outcome; an "
    "opinion about a judge; what to say to law enforcement, ICE, or a court; how "
    "to evade authorities; medical, tax, or financial advice; or whether a "
    "document or person is fraudulent. When refusing, return ONLY this JSON "
    "object:\n"
    '{\"refused\": true, '
    '\"refusal_reason\": \"<one of: legal_strategy, hearing_attendance, '
    "admit_deny, eligibility, outcome, judge_bias, le_scripts, evasion, "
    'other_professional, document_authenticity, other>\", '
    '\"refusal_text_es\": \"<one or two short, kind Spanish sentences: that you '
    "cannot help with that, what you CAN do instead, and to contact free legal "
    'aid>\"}.\n\n'
    "Otherwise, answer the question normally and return ONLY this JSON object: "
    '{\"answer_es\": \"...\", \"citation_ids\": [\"...\"]}.'
)


def lambda_handler(event, _context):
    """Entry point for POST /ask."""
    started = h.monotonic_ms()
    try:
        return _handle(event, started)
    except _NotFound as nf:
        return h.response(404, {"error": str(nf)})
    except Exception as exc:  # noqa: BLE001
        request_id = getattr(_context, "aws_request_id", str(uuid.uuid4()))
        print(json.dumps({"level": "error", "msg": "ask_unhandled", "error": str(exc),
                          "request_id": request_id}))
        return h.response(500, {"error": "internal error", "request_id": request_id})


class _NotFound(Exception):
    pass


def _handle(event, started):
    body = h.parse_body(event)
    session_id = body.get("session_id")
    document_id = body.get("document_id")
    question = (body.get("question") or "").strip()
    audio_b64 = body.get("audio_base64")
    audio_format = (body.get("audio_format") or "").lower()

    # --- 1. validate ------------------------------------------------------
    if not session_id or not document_id:
        return h.response(400, {"error": "session_id and document_id required"})
    has_q = bool(question)
    has_audio = bool(audio_b64)
    if has_q and has_audio:
        return h.response(400, {"error": "provide exactly one of question or audio_base64"})
    if not has_q and not has_audio:
        return h.response(400, {"error": "provide exactly one of question or audio_base64"})
    if has_audio and audio_format not in AUDIO_FORMATS:
        return h.response(400, {"error": f"audio_format required, one of {AUDIO_FORMATS}"})

    # --- 2. transcribe (voice mode) --------------------------------------
    transcribed = None
    if has_audio:
        try:
            audio_bytes = base64.b64decode(audio_b64, validate=True)
        except (binascii.Error, ValueError):
            return h.response(400, {"error": "audio_base64 is not valid base64"})
        transcribed = _transcribe(audio_bytes, audio_format, session_id)
        if not transcribed:
            return h.response(
                200,
                {
                    "session_id": session_id,
                    "question_transcribed": None,
                    "answer_es": None,
                    "answer_audio_url": None,
                    "citations": [],
                    "was_refused": False,
                    "refusal_reason": None,
                    "refusal_text_es": None,
                    "legal_aid_options": h.legal_aid_options(),
                    "latency_ms": round(h.monotonic_ms() - started),
                    "_note": "no se pudo transcribir el audio; intenta escribir tu pregunta",
                },
            )
        question = transcribed

    # --- 3. fetch the scanned document for grounding ---------------------
    image_bytes, image_fmt = _load_document(session_id, document_id)

    # --- 4. KB retrieval -------------------------------------------------
    kb_chunks = h.kb_retrieve(question, max_results=4)
    kb_context = "\n\n".join(
        f"[{c['kb_chunk_id']}] {c['text']}" for c in kb_chunks if c["text"]
    )

    # --- 5. Bedrock Converse (Guardrail attached) ------------------------
    ask_prompt = h.load_prompt("ask_prompt.md", _FALLBACK_ASK)
    system_prompt = h.load_prompt("system_prompt.md", "")
    text_model = h.env("TEXT_MODEL_ID", "us.anthropic.claude-sonnet-4-6")

    user_text = (
        f"{ask_prompt}\n\n"
        f"KNOWLEDGE BASE CONTEXT:\n{kb_context or '(none retrieved)'}\n\n"
        f"USER QUESTION:\n{question}"
    )
    content_blocks = [h.text_block(user_text)]
    if image_bytes and image_fmt:
        content_blocks.insert(0, h.image_block(image_bytes, image_fmt))

    res = h.converse(
        model_id=text_model,
        content_blocks=content_blocks,
        system=system_prompt or None,
        max_tokens=1200,
    )

    # --- 6. refusal path — two layers: Guardrail OR prompt-detected ------
    refused, reason, refusal_text, refusal_source = h.resolve_refusal(res)
    if refused:
        _log_refusal(session_id, question, reason)
        print(json.dumps({"level": "info", "msg": "refusal",
                          "reason": reason, "source": refusal_source}))
        return h.response(
            200,
            {
                "session_id": session_id,
                "question_transcribed": transcribed,
                "answer_es": None,
                "answer_audio_url": None,
                "citations": [],
                "was_refused": True,
                "refusal_reason": reason,
                "refusal_text_es": refusal_text,
                "legal_aid_options": h.legal_aid_options(),
                "latency_ms": round(h.monotonic_ms() - started),
            },
        )

    # --- 7. answer path --------------------------------------------------
    answer_data = h.extract_json(res.text) or {}
    answer_es = answer_data.get("answer_es") or res.text.strip()
    used_chunk_ids = set(answer_data.get("citation_ids") or [])
    citations = _build_citations(kb_chunks, used_chunk_ids)

    answer_audio_url = None
    if answer_es:
        try:
            audio = h.synthesize_spanish(answer_es)
            audio_key = f"{session_id}/{document_id}-answer-{uuid.uuid4()}.mp3"
            h.s3_put_ephemeral(audio_key, audio, "audio/mpeg")
            answer_audio_url = h.s3_presign(audio_key, expires=3600)
        except Exception as exc:  # noqa: BLE001 - audio is non-critical
            print(json.dumps({"level": "warn", "msg": "polly_failed", "error": str(exc)}))

    return h.response(
        200,
        {
            "session_id": session_id,
            "question_transcribed": transcribed,
            "answer_es": answer_es,
            "answer_audio_url": answer_audio_url,
            "citations": citations,
            "was_refused": False,
            "refusal_reason": None,
            "refusal_text_es": None,
            "legal_aid_options": h.legal_aid_options(),
            "latency_ms": round(h.monotonic_ms() - started),
            "cost_estimate_usd": h.estimate_cost(text_model, res.usage),
        },
    )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _load_document(session_id, document_id):
    """Return (image_bytes, fmt) for the scanned document, or raise _NotFound.

    /scan stores the image as <session>/<document>.jpg or .png. The 1h S3
    lifecycle means an expired document_id naturally raises -> 404 (contract).
    """
    for ext, fmt in (("jpg", "jpeg"), ("jpeg", "jpeg"), ("png", "png")):
        try:
            data = h.s3_get(f"{session_id}/{document_id}.{ext}")
            return data, fmt
        except Exception:  # noqa: BLE001 - try next extension
            continue
    raise _NotFound("document_id not found or expired (>1h old)")


def _transcribe(audio_bytes, audio_format, session_id):
    """Transcribe Spanish audio with AWS Transcribe (batch job, bounded poll)."""
    job_name = f"cc-{session_id[:8]}-{uuid.uuid4().hex[:8]}"
    audio_key = f"{session_id}/ask-audio-{uuid.uuid4().hex}.{audio_format}"
    h.s3_put_ephemeral(audio_key, audio_bytes, f"audio/{audio_format}")
    media_uri = f"s3://{h.env('UPLOADS_BUCKET')}/{audio_key}"

    transcribe = h.client("transcribe")
    transcribe.start_transcription_job(
        TranscriptionJobName=job_name,
        LanguageCode="es-US",
        MediaFormat=audio_format,
        Media={"MediaFileUri": media_uri},
    )

    deadline = time.monotonic() + TRANSCRIBE_POLL_SECONDS
    while time.monotonic() < deadline:
        job = transcribe.get_transcription_job(TranscriptionJobName=job_name)
        status = job["TranscriptionJob"]["TranscriptionJobStatus"]
        if status == "COMPLETED":
            uri = job["TranscriptionJob"]["Transcript"]["TranscriptFileUri"]
            return _fetch_transcript_text(uri)
        if status == "FAILED":
            print(json.dumps({"level": "warn", "msg": "transcribe_failed",
                              "reason": job["TranscriptionJob"].get("FailureReason")}))
            return None
        time.sleep(1.5)
    print(json.dumps({"level": "warn", "msg": "transcribe_timeout", "job": job_name}))
    return None


def _fetch_transcript_text(uri):
    try:
        with urllib.request.urlopen(uri, timeout=5) as resp:  # noqa: S310
            data = json.loads(resp.read())
        return data["results"]["transcripts"][0]["transcript"].strip() or None
    except Exception as exc:  # noqa: BLE001
        print(json.dumps({"level": "warn", "msg": "transcript_fetch_failed", "error": str(exc)}))
        return None


def _build_citations(kb_chunks, used_chunk_ids):
    """Build the API_CONTRACT citation list from KB chunks the model cited."""
    citations = []
    for c in kb_chunks:
        if used_chunk_ids and c["kb_chunk_id"] not in used_chunk_ids:
            continue
        citations.append(
            {
                "id": c["kb_chunk_id"],
                "source_label": _source_label(c["source_uri"]),
                "kb_chunk_id": c["kb_chunk_id"],
            }
        )
    # If the model named no chunks, surface all retrieved chunks as citations.
    if not citations and not used_chunk_ids:
        for c in kb_chunks:
            citations.append(
                {
                    "id": c["kb_chunk_id"],
                    "source_label": _source_label(c["source_uri"]),
                    "kb_chunk_id": c["kb_chunk_id"],
                }
            )
    return citations


def _source_label(uri):
    if not uri:
        return "Base de conocimiento Carta Clara"
    name = uri.rstrip("/").split("/")[-1]
    return name or "Base de conocimiento Carta Clara"


def _log_refusal(session_id, question, reason):
    """Write a PII-redacted refusal to DynamoDB. The question is hashed, never stored."""
    from datetime import datetime, timezone

    table = h.resource("dynamodb").Table(h.env("REFUSAL_TABLE"))
    now = datetime.now(timezone.utc)
    try:
        table.put_item(
            Item={
                "session_id": session_id,
                "ts": now.isoformat(),
                "question_hash": hashlib.sha256(question.encode("utf-8")).hexdigest()[:16],
                "reason": reason,
                "ttl": int(now.timestamp()) + 3600,
            }
        )
    except Exception as exc:  # noqa: BLE001 - logging must not break the refusal
        print(json.dumps({"level": "error", "msg": "refusal_log_write_failed",
                          "error": str(exc)}))
