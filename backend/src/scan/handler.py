"""POST /scan — Carta Clara document scan endpoint.

Flow (API_CONTRACT.md § POST /scan):
  1. Validate the base64 image (presence, size, JPEG/PNG magic bytes).
  2. Write the image to S3 under the session, tagged ephemeral (TENETS §7).
  3. Amazon Textract -> OCR the image to plain text (fast, cheap, deterministic).
  4. Bedrock text-only (Claude Sonnet 4.6) + extraction_prompt + the Textract
     text -> structured JSON. Guardrail attached -> if it intervenes, return
     the refusal-case shape.
  5. Bedrock text + spanish_summary_prompt -> headline summary + section cards.
  6. Polly -> Spanish audio of the headline summary -> S3 -> presigned URL.
  7. Assemble and return the response in the API_CONTRACT shape.

Tenets enforced here:
  §1 Trust before features — redaction flags surfaced, citations carried through.
  §2 Refuse before answering — Guardrail intervention -> refusal-case response.
  §6 Synthetic only — is_demo_document / demo_watermark_detected echoed from extraction.
  §7 Ephemeral — image stored with a 1h-intent tag; audio presigned 1h.
"""

import base64
import binascii
import json
import uuid

import helpers as h

MAX_IMAGE_BYTES = 10 * 1024 * 1024  # 10MB (API_CONTRACT)

# Fallback prompts so the handler + smoke tests work before Sage's files land
# (SAGE-02 / SAGE-03). The real prompts override these via the loader.
_FALLBACK_EXTRACTION = (
    "You are extracting structured data from a U.S. immigration document image. "
    "PII has already been redacted before you. Return ONLY a JSON object with keys: "
    "document_type, issuing_agency, country_of_origin, country_of_citizenship, "
    "hearing_date (YYYY-MM-DD), hearing_time (HH:MM), court_name, court_address, "
    "issuing_officer, alleged_basis_summary, charges_cited (array), "
    "deadline_critical (YYYY-MM-DD), is_demo_document (bool), "
    "demo_watermark_detected (bool). Use null for unknown fields. "
    "If the document appears to contain real un-redacted PII, instead return "
    '{\"refuse\": true, \"reason\": \"document appears non-synthetic\"}.'
)
_FALLBACK_SUMMARY = (
    "You explain an immigration document in plain Spanish for a reader with low "
    "literacy. You give information, never legal advice (TENETS §3). Return ONLY a "
    "JSON object: {summary_en, summary_es, sections:[{section_title_en, "
    "section_title_es, section_body_es, section_body_full_es, citation_ids:[]}]}. "
    "Keep summary_es to 1-2 short sentences."
)


def lambda_handler(event, _context):
    """Entry point for POST /scan."""
    started = h.monotonic_ms()
    try:
        return _handle(event, started)
    except Exception as exc:  # noqa: BLE001
        if _is_throttling(exc):
            return h.response(429, {"error": "service busy, retry in 5s"})
        request_id = getattr(_context, "aws_request_id", str(uuid.uuid4()))
        print(json.dumps({"level": "error", "msg": "scan_unhandled", "error": str(exc),
                          "request_id": request_id}))
        return h.response(500, {"error": "internal error", "request_id": request_id})


def _is_throttling(exc) -> bool:
    name = exc.__class__.__name__
    if name in ("ThrottlingException", "TooManyRequestsException"):
        return True
    code = getattr(exc, "response", {}).get("Error", {}).get("Code", "")
    return code in ("ThrottlingException", "TooManyRequestsException", "Throttling")


def _handle(event, started):
    body = h.parse_body(event)
    session_id = body.get("session_id") or str(uuid.uuid4())
    document_id = str(uuid.uuid4())
    image_b64 = body.get("image_base64") or ""
    reading_level = body.get("reading_level") or "intermediate"
    if reading_level not in ("beginner", "intermediate", "full"):
        reading_level = "intermediate"
    language = (body.get("language") or "es").lower()
    if language not in ("en", "es"):
        language = "es"

    # --- 1. validate ------------------------------------------------------
    if not image_b64:
        return h.response(400, {"error": "image_base64 required (or too large)"})
    try:
        image_bytes = base64.b64decode(image_b64, validate=True)
    except (binascii.Error, ValueError):
        return h.response(400, {"error": "image_base64 required (or too large)"})
    if not image_bytes or len(image_bytes) > MAX_IMAGE_BYTES:
        return h.response(400, {"error": "image_base64 required (or too large)"})

    fmt = _detect_format(image_bytes)
    if fmt is None:
        return h.response(415, {"error": "image must be JPEG or PNG"})

    # --- 2. store ephemerally --------------------------------------------
    ext = "jpg" if fmt == "jpeg" else "png"
    image_key = f"{session_id}/{document_id}.{ext}"
    h.s3_put_ephemeral(image_key, image_bytes, f"image/{fmt}")

    # --- 3. OCR with Amazon Textract -------------------------------------
    # Textract is the dedicated text-extraction service: faster, cheaper, and
    # more deterministic than asking a multimodal LLM to read pixels.
    document_text = h.textract_detect_text(image_bytes)
    if not document_text.strip():
        return h.response(
            422,
            {"error": "could not extract text from image",
             "detail": "Textract returned no readable text — retake the photo with better lighting and framing."},
        )

    # --- 4. semantic extraction (text-only LLM, Guardrail attached) ------
    extraction_prompt = h.load_prompt("extraction_prompt.md", _FALLBACK_EXTRACTION)
    system_prompt = h.load_prompt("system_prompt.md", "")
    text_model = h.env("TEXT_MODEL_ID", "us.anthropic.claude-sonnet-4-6")

    extract_input = (
        f"{extraction_prompt}\n\n"
        f"---\nOCR-EXTRACTED DOCUMENT TEXT (verbatim from Textract, line-by-line):\n"
        f"{document_text}\n---"
    )
    extract_res = h.converse(
        model_id=text_model,
        content_blocks=[h.text_block(extract_input)],
        system=system_prompt or None,
        max_tokens=1200,
    )

    # Guardrail intervened on the document itself -> refusal case
    if extract_res.intervened:
        return _refusal_response(session_id, "document appears non-synthetic", started, language)

    extraction_raw = h.extract_json(extract_res.text) or {}
    if extraction_raw.get("refuse"):
        return _refusal_response(
            session_id, extraction_raw.get("reason", "document could not be verified"), started, language
        )
    if not extraction_raw:
        return h.response(
            422,
            {"error": "could not extract structured data",
             "detail": "model did not return structured JSON"},
        )

    extraction = _normalize_extraction(extraction_raw)

    # --- 4. summary + section cards (in the requested language) ----------
    summary_prompt = h.load_prompt("spanish_summary_prompt.md", _FALLBACK_SUMMARY)
    summary_prompt = (
        f"{summary_prompt}\n\nPARAMETERS:\nreading_level: {reading_level}\n"
        f"language: {language}"
    )
    if language == "en":
        summary_prompt += (
            "\n\nLANGUAGE OVERRIDE: Produce ALL output in ENGLISH. The field "
            "names ending in `_es` in the output schema are historical — write "
            "English text into them. The response must contain NO Spanish at "
            "all. summary_en and summary_es should both be the same English text."
        )
    # Summary uses Sonnet because the structured-section prompt requires the
    # higher reasoning quality to follow the "quote a specific extracted fact
    # in every sentence" rule. Nova Pro is faster but produces generic
    # paraphrases that defeat the point. Latency stays under the API Gateway
    # 30s ceiling via the tightened prompt + 1000 max_tokens cap.
    summary_model = h.env("TEXT_MODEL_ID", "us.anthropic.claude-sonnet-4-6")

    summary_input = (
        f"{summary_prompt}\n\nEXTRACTED DOCUMENT DATA (JSON):\n"
        f"{json.dumps(extraction, ensure_ascii=False)}"
    )
    summary_res = h.converse(
        model_id=summary_model,
        content_blocks=[h.text_block(summary_input)],
        system=system_prompt or None,
        max_tokens=1000,
    )
    if summary_res.intervened:
        return _refusal_response(session_id, "summary generation blocked by Guardrail", started, language)

    summary_data = h.extract_json(summary_res.text) or {}
    summary_en = summary_data.get("summary_en") or ""
    summary_es = summary_data.get("summary_es") or summary_res.text.strip()
    sections = _normalize_sections(summary_data.get("sections", []))

    # --- 5. Polly audio of the headline summary --------------------------
    # Polly SynthesizeSpeech is hard-capped at 3000 chars. The summary is
    # *supposed* to be 1-2 sentences but the model sometimes overshoots; clamp
    # at 2800 chars so we still get audio instead of a TextLengthExceededException.
    audio_url = None
    spoken_text = summary_es if language == "es" else (summary_en or summary_es)
    if spoken_text:
        if len(spoken_text) > 2800:
            spoken_text = spoken_text[:2800].rsplit(" ", 1)[0] + "…"
        try:
            audio_bytes = h.synthesize_speech(spoken_text, language=language)
            audio_key = f"{session_id}/{document_id}-summary.mp3"
            h.s3_put_ephemeral(audio_key, audio_bytes, "audio/mpeg")
            audio_url = h.s3_presign(audio_key, expires=3600)
        except Exception as exc:  # noqa: BLE001 - audio is non-critical
            print(json.dumps({"level": "warn", "msg": "polly_failed", "error": str(exc)}))

    # --- 6. assemble -----------------------------------------------------
    total_usage = _merge_usage(extract_res.usage, summary_res.usage)
    cost = h.estimate_cost(text_model, extract_res.usage) + h.estimate_cost(
        summary_model, summary_res.usage
    )

    result = {
        "session_id": session_id,
        "document_id": document_id,
        "language": language,
        "extraction": extraction,
        "summary_en": summary_en,
        "summary_es": summary_es,
        "audio_url": audio_url,
        "sections": sections,
        "urgency": _build_urgency(extraction, language),
        "scam_red_flags": [],  # populated by /ask scam-check on a separate text input
        "court_brief": _build_court_brief(extraction, language),
        "legal_aid_options": h.legal_aid_options(),
        "citations": _collect_citations(sections),
        "latency_ms": round(h.monotonic_ms() - started),
        "cost_estimate_usd": round(cost, 6),
        "_token_usage": total_usage,
    }
    return h.response(200, result)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _detect_format(data: bytes):
    """Return 'jpeg', 'png', or None from magic bytes."""
    if data[:3] == b"\xff\xd8\xff":
        return "jpeg"
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        return "png"
    return None


def _normalize_extraction(raw: dict) -> dict:
    """Map a model extraction object onto the API_CONTRACT `extraction` shape."""
    return {
        "document_type": raw.get("document_type"),
        "issuing_agency": raw.get("issuing_agency"),
        # PII is masked by the Guardrail before the model — these are always true.
        "names_redacted": True,
        "a_number_redacted": True,
        "address_redacted": True,
        "country_of_origin": raw.get("country_of_origin"),
        "country_of_citizenship": raw.get("country_of_citizenship"),
        "hearing_date": raw.get("hearing_date"),
        "hearing_time": raw.get("hearing_time"),
        "court_name": raw.get("court_name"),
        "court_address": raw.get("court_address"),
        "issuing_officer": raw.get("issuing_officer"),
        "alleged_basis_summary": raw.get("alleged_basis_summary"),
        "charges_cited": raw.get("charges_cited") or [],
        "deadline_critical": raw.get("deadline_critical"),
        "is_demo_document": bool(raw.get("is_demo_document", False)),
        "demo_watermark_detected": bool(raw.get("demo_watermark_detected", False)),
    }


def _normalize_sections(sections) -> list:
    out = []
    for s in sections or []:
        if not isinstance(s, dict):
            continue
        out.append(
            {
                "section_title_en": s.get("section_title_en", ""),
                "section_title_es": s.get("section_title_es", ""),
                "section_body_es": s.get("section_body_es", ""),
                "section_body_full_es": s.get("section_body_full_es")
                or s.get("section_body_es", ""),
                "citation_ids": s.get("citation_ids") or [],
            }
        )
    return out


def _build_urgency(extraction: dict, language: str = "es") -> dict:
    deadline = extraction.get("deadline_critical") or extraction.get("hearing_date")
    is_urgent = deadline is not None
    label = None
    if deadline:
        prefix = "Important date" if language == "en" else "Fecha importante"
        label = f"{prefix}: {deadline}"
        if extraction.get("hearing_time"):
            label += f", {extraction['hearing_time']}"
    note = (
        "Verify this date directly with the court. The court's contact "
        "information appears on your document. Do not rely on this app alone."
    ) if language == "en" else (
        "Verifica esta fecha directamente con la corte. La información de la "
        "corte aparece en tu documento. No dependas solo de esta aplicación."
    )
    return {
        "is_urgent": is_urgent,
        "deadline_date": deadline,
        "deadline_label_es": label,
        "verification_note_es": note,
    }


def _build_court_brief(extraction: dict, language: str = "es"):
    court_name = extraction.get("court_name")
    if not court_name:
        return None
    if language == "en":
        return {
            "court_name": court_name,
            "address": extraction.get("court_address") or "",
            "phone": "",
            "what_to_expect_es": (
                "Courts expect people who receive this notice to attend. "
                "Whether and how to attend is a decision for you and a lawyer — "
                "call free legal aid before the date. If you do attend, the "
                "hearing is before an immigration judge. It is not a final "
                "decision. You have the right to a lawyer and to a free "
                "interpreter."
            ),
            "what_to_bring_es": [
                "If you attend, courts typically allow attendees to bring:",
                "Your original document (the court notice)",
                "A photo ID",
                "Any immigration papers you have",
                "Your lawyer's name and phone, if you already have one",
            ],
            "what_not_to_bring_es": [
                "Items courts do not allow inside the courthouse:",
                "Weapons or sharp objects",
                "Fake or altered documents",
            ],
            "dress_code_es": "If you attend, courts expect clean, formal clothing — like for an important appointment.",
        }
    return {
        "court_name": court_name,
        "address": extraction.get("court_address") or "",
        "phone": "",
        "what_to_expect_es": (
            "Las cortes esperan que las personas que reciben este aviso asistan. "
            "Si vas a asistir, o cómo asistir, es una decisión que debes tomar "
            "con un abogado — llama a ayuda legal gratis antes de la fecha. "
            "Si decides asistir, la audiencia es ante un juez de inmigración. "
            "No es una decisión final. Tienes derecho a tener un abogado y a "
            "un intérprete sin costo."
        ),
        "what_to_bring_es": [
            "Si asistes, las cortes generalmente permiten que lleves:",
            "Tu documento original (el aviso de la corte)",
            "Una identificación",
            "Cualquier papel de inmigración que tengas",
            "El nombre y teléfono de tu abogado, si ya tienes uno",
        ],
        "what_not_to_bring_es": [
            "Cosas que las cortes no permiten dentro del edificio:",
            "Armas u objetos filosos",
            "Documentos falsos o alterados",
        ],
        "dress_code_es": "Si asistes, las cortes esperan ropa limpia y formal — como para una cita importante.",
    }


def _collect_citations(sections: list) -> list:
    """Flatten unique citation IDs referenced by section cards."""
    seen = {}
    for s in sections:
        for cid in s.get("citation_ids", []):
            if cid not in seen:
                seen[cid] = {
                    "id": cid,
                    "source_label": "",
                    "kb_chunk_id": cid,
                    "url": "",
                }
    return list(seen.values())


def _merge_usage(*usages) -> dict:
    total = {"inputTokens": 0, "outputTokens": 0}
    for u in usages:
        total["inputTokens"] += (u or {}).get("inputTokens", 0)
        total["outputTokens"] += (u or {}).get("outputTokens", 0)
    return total


def _refusal_response(session_id, reason, started, language: str = "es"):
    """API_CONTRACT § POST /scan — Refusal case (still HTTP 200)."""
    text = (
        "I cannot safely process this document. This can happen when the "
        "document appears to contain real personal information that has not "
        "been protected. For your safety, take the document directly to a "
        "free legal-aid service — they can review it with you."
    ) if language == "en" else (
        "No puedo procesar este documento de forma segura. Esto puede pasar "
        "si el documento parece contener información personal real sin "
        "proteger. Por tu seguridad, lleva el documento directamente a un "
        "servicio de ayuda legal gratis — ellos pueden revisarlo contigo."
    )
    return h.response(
        200,
        {
            "session_id": session_id,
            "language": language,
            "was_refused": True,
            "refusal_reason": reason,
            "refusal_text_es": text,
            "legal_aid_options": h.legal_aid_options(),
            "latency_ms": round(h.monotonic_ms() - started),
        },
    )
