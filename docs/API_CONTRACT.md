# Carta Clara — API Contract

**Source of truth** for the REST contract between the iOS app and the backend. Koda implements against this. Riku codes Swift models against this. If you need to change the shape, escalate to Claudio first.

**Base URL:** `https://<your-api-id>.execute-api.us-west-2.amazonaws.com`
*(Deployed 2026-05-16 via `sam deploy --guided`, stack `carta-clara-mvp` in us-west-2.)*

**Auth:** None for hackathon MVP. Open API.

**Content type:** `application/json` unless noted.

---

## POST /scan

Submit a photographed document for extraction, summary, and Spanish translation.

### Request

```json
{
  "session_id": "string (UUID v4, optional — backend generates if absent)",
  "image_base64": "string (base64-encoded JPEG or PNG, max 10MB)",
  "reading_level": "beginner | intermediate | full (default: intermediate)"
}
```

### Response (200 OK)

```json
{
  "session_id": "string (UUID v4, echoed back or newly generated)",
  "document_id": "string (UUID v4, references the S3 object)",
  "extraction": {
    "document_type": "string (e.g., 'Notice to Appear (Form I-862)')",
    "issuing_agency": "string",
    "names_redacted": true,
    "a_number_redacted": true,
    "address_redacted": true,
    "country_of_origin": "string or null",
    "country_of_citizenship": "string or null",
    "hearing_date": "string (ISO date YYYY-MM-DD) or null",
    "hearing_time": "string (HH:MM, 24h) or null",
    "court_name": "string or null",
    "court_address": "string or null",
    "issuing_officer": "string or null",
    "alleged_basis_summary": "string or null",
    "charges_cited": ["string", "..."],
    "deadline_critical": "string (ISO date) or null",
    "is_demo_document": true,
    "demo_watermark_detected": true
  },
  "summary_en": "string (1–2 sentence headline summary in English)",
  "summary_es": "string (1–2 sentence headline summary in plain Spanish)",
  "audio_url": "string (S3 presigned URL to Polly-synthesized Spanish audio, mp3, 1h expiry) or null",
  "sections": [
    {
      "section_title_en": "string",
      "section_title_es": "string",
      "section_body_es": "string (plain Spanish, reading-level-tuned)",
      "section_body_full_es": "string (full-detail Spanish, for the slider's max setting)",
      "citation_ids": ["string"]
    }
  ],
  "urgency": {
    "is_urgent": true,
    "deadline_date": "string (ISO date) or null",
    "deadline_label_es": "string (e.g., 'Fecha de corte: 15 de octubre de 2026, 9:00 AM')",
    "verification_note_es": "string (instruction to verify with court directly)"
  },
  "scam_check_summary_es": "string (educational Spanish message — shown even when zero flags detected; explains what to watch for going forward)",
  "scam_red_flags": [
    {
      "pattern_name": "string (e.g., 'guaranteed_result')",
      "pattern_description_es": "string",
      "citation_url": "string",
      "citation_source": "FTC | USCIS"
    }
  ],
  "court_brief": {
    "court_name": "string",
    "address": "string",
    "phone": "string",
    "what_to_expect_es": "string",
    "what_to_bring_es": ["string"],
    "what_not_to_bring_es": ["string"],
    "dress_code_es": "string"
  } | null,
  "legal_aid_options": [
    {
      "name": "string (e.g., 'Northwest Immigrant Rights Project')",
      "phone": "string",
      "address": "string",
      "hours": "string",
      "languages": ["string"],
      "free": true
    }
  ],
  "citations": [
    {
      "id": "string",
      "source_label": "string (e.g., 'USCIS Avoid Scams page')",
      "kb_chunk_id": "string",
      "url": "string"
    }
  ],
  "latency_ms": 0,
  "cost_estimate_usd": 0.0
}
```

### Errors

| Status | When | Body |
|--------|------|------|
| 400 | Missing or oversized image | `{"error": "image_base64 required (or too large)"}` |
| 415 | Unsupported image format | `{"error": "image must be JPEG or PNG"}` |
| 422 | Extraction failed | `{"error": "could not extract structured data", "detail": "..."}` |
| 429 | Bedrock throttled | `{"error": "service busy, retry in 5s"}` |
| 500 | Unhandled | `{"error": "internal error", "request_id": "..."}` |

### Refusal case

If Guardrails intervenes on the multimodal call (e.g., document appears to contain real PII or attempts prompt injection), the response is still 200 OK but:

```json
{
  "session_id": "...",
  "was_refused": true,
  "refusal_reason": "string (e.g., 'document appears non-synthetic')",
  "refusal_text_es": "string (safe-replacement text)",
  "legal_aid_options": [...]
}
```

---

## POST /ask

Ask a follow-up question about a previously scanned document. Voice or text.

### Request

```json
{
  "session_id": "string (UUID v4, required — must match a prior /scan session)",
  "document_id": "string (UUID v4, from /scan response)",
  "question": "string (text — present if not using audio)",
  "audio_base64": "string (base64 audio — present if voice mode)",
  "audio_format": "wav | mp3 | webm (required if audio_base64 present)"
}
```

Exactly one of `question` or `audio_base64` must be present.

### Response (200 OK)

```json
{
  "session_id": "string",
  "question_transcribed": "string (if audio was transcribed, the resulting text)",
  "answer_es": "string (Spanish answer if allowed by Guardrails) or null",
  "answer_audio_url": "string (S3 presigned URL for Polly-synthesized audio answer, 1h expiry) or null",
  "citations": [
    {
      "id": "string",
      "source_label": "string",
      "kb_chunk_id": "string"
    }
  ],
  "was_refused": false,
  "refusal_reason": "string (one of: legal_strategy | hearing_attendance | admit_deny | eligibility | outcome | judge_bias | le_scripts | evasion | other_professional | document_authenticity) | null",
  "refusal_text_es": "string (safe-replacement text, only present if was_refused=true) | null",
  "legal_aid_options": [...],
  "latency_ms": 0
}
```

### Refusal case

When `was_refused = true`:
- `answer_es` is null
- `refusal_text_es` is the safe-replacement text from `docs/DENIED_TOPICS.md` for that topic
- `refusal_reason` is the topic name
- `legal_aid_options` is always populated

The iOS app increments the refusal counter on receiving `was_refused: true`.

### Errors

| Status | When |
|--------|------|
| 400 | Missing `session_id` or `document_id` |
| 400 | Both `question` and `audio_base64` present |
| 400 | Neither `question` nor `audio_base64` present |
| 404 | `document_id` not found or expired (>1h old) |
| 500 | Unhandled |

---

## POST /scan/packet

Generate the Response Preparation Packet for a previously scanned document.

### Request

```json
{
  "session_id": "string",
  "document_id": "string"
}
```

### Response (200 OK)

```json
{
  "session_id": "string",
  "packet": {
    "title_es": "string",
    "what_this_says_es": "string (translated summary)",
    "your_deadline": {
      "date": "string (ISO)",
      "label_es": "string"
    },
    "documents_to_gather_es": ["string"],
    "extension_request_template": "string (pre-filled Markdown for an extension request)",
    "legal_aid_phone_script_es": "string",
    "questions_for_lawyer_es": ["string"],
    "cover_sheet_es": "string (\"Bring this to your appointment. Your lawyer will write the official response.\")"
  },
  "legal_aid_options": [...],
  "pdf_url": "string (S3 presigned URL to a rendered PDF, 1h expiry) or null"
}
```

If `pdf_url` is null in v1, iOS renders the Markdown locally.

---

## GET /refusal-log

Get the count and recent refusals for the current session. The iOS refusal counter polls this.

### Request

Query parameter: `session_id` (required)

```
GET /refusal-log?session_id=abc-123-def
```

### Response (200 OK)

```json
{
  "session_id": "string",
  "count": 0,
  "refusals": [
    {
      "ts": "string (ISO datetime)",
      "reason": "string (one of the denied-topic names)",
      "topic_label_es": "string (Spanish label for the topic, displayed in the refusal log UI)"
    }
  ]
}
```

Limit to 20 most recent. Sorted descending by timestamp.

---

## CORS

API Gateway is configured to allow:
- Origins: `*` (hackathon scope; tighten for production)
- Methods: `GET, POST, OPTIONS`
- Headers: `*`
- Max age: 600s

iOS app does not need to handle CORS preflight (URLSession doesn't enforce it on native).

---

## Versioning

This is v1. No explicit version in path. If we need to break the contract post-launch, we add `/v2/` paths and run both for a grace period.

---

## Field naming conventions

- `snake_case` for JSON fields (matches Lambda Python idioms)
- ISO 8601 for all timestamps and dates
- Boolean fields end in `_redacted`, `_detected`, `_refused`, etc. for readability
- Spanish content fields end in `_es`; English in `_en`. Mixed-language responses use both.
- Nullable fields are explicitly typed as `string | null` in this doc

---

## Source of truth note

If the iOS app and the Lambda disagree on a field shape, **this document wins**. Both sides update their code, not this contract. Changes to this contract require Claudio's sign-off.
