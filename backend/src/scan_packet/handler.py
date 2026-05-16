"""POST /scan/packet — Carta Clara Response Preparation Packet.

Generates the printable preparation packet for a previously scanned document
(API_CONTRACT.md § POST /scan/packet). Riku's `ResponsePacketView` consumes
this response.

Flow:
  1. Validate: session_id + document_id required.
  2. Re-fetch the scanned document image from S3 (404 if expired — 1h lifecycle).
  3. Bedrock Converse (Guardrail attached) with response_packet_prompt -> the
     structured `packet` JSON object.
  4. Assemble the API_CONTRACT response. pdf_url is null in v1 — iOS renders
     the Markdown locally (contract note).

Tenets:
  §2 Refuse before answering — a Guardrail intervention degrades to a safe
     packet that routes the user to free legal aid (never a blank failure).
  §3 Information, not advice — the packet helps the user PREPARE for a lawyer;
     it never drafts a substantive response. The extension-request template is
     procedural only, and clearly says the lawyer writes the official response.
  §7 Ephemeral — reads the existing S3 object; stores nothing new of substance.
"""

import json
import uuid

import helpers as h

# Fallback prompt so the handler + smoke tests work before SAGE-05 lands.
# The real backend/prompts/response_packet_prompt.md overrides this.
_FALLBACK_PACKET = (
    "You generate a Response Preparation Packet that helps a Spanish-speaking "
    "person PREPARE to meet a free legal aid attorney about their immigration "
    "document. You give INFORMATION, never legal advice (TENETS §3): you do not "
    "choose a legal strategy, predict outcomes, or draft a substantive response "
    "to any court or agency. Read the attached document image and return ONLY a "
    "JSON object with these keys:\n"
    "  title_es: short Spanish title for the packet\n"
    "  what_this_says_es: 1 plain-Spanish paragraph explaining the document\n"
    "  your_deadline: {date: 'YYYY-MM-DD' or null, label_es: string}\n"
    "  documents_to_gather_es: array of Spanish strings (evidence to bring)\n"
    "  extension_request_template: Markdown for a PROCEDURAL request to "
    "reschedule, to be used ONLY if the person has a documented conflict; it "
    "must state the attorney writes the official response\n"
    "  legal_aid_phone_script_es: a short Spanish script to call a clinic\n"
    "  questions_for_lawyer_es: array of Spanish questions to ask the attorney\n"
    "  cover_sheet_es: one Spanish sentence reminding the person to bring this "
    "packet to their appointment and that the lawyer writes the official reply."
)


def lambda_handler(event, _context):
    """Entry point for POST /scan/packet."""
    started = h.monotonic_ms()
    try:
        return _handle(event, started)
    except _NotFound as nf:
        return h.response(404, {"error": str(nf)})
    except Exception as exc:  # noqa: BLE001
        request_id = getattr(_context, "aws_request_id", str(uuid.uuid4()))
        print(json.dumps({"level": "error", "msg": "scan_packet_unhandled",
                          "error": str(exc), "request_id": request_id}))
        return h.response(500, {"error": "internal error", "request_id": request_id})


class _NotFound(Exception):
    pass


def _handle(event, started):
    body = h.parse_body(event)
    session_id = body.get("session_id")
    document_id = body.get("document_id")

    # --- 1. validate ------------------------------------------------------
    if not session_id or not document_id:
        return h.response(400, {"error": "session_id and document_id required"})

    # --- 2. fetch the scanned document -----------------------------------
    image_bytes, image_fmt = _load_document(session_id, document_id)

    # --- 3. Bedrock Converse (Guardrail attached) ------------------------
    packet_prompt = h.load_prompt("response_packet_prompt.md", _FALLBACK_PACKET)
    system_prompt = h.load_prompt("system_prompt.md", "")
    text_model = h.env("TEXT_MODEL_ID", "us.anthropic.claude-sonnet-4-6")

    res = h.converse(
        model_id=text_model,
        content_blocks=[
            h.image_block(image_bytes, image_fmt),
            h.text_block(packet_prompt),
        ],
        system=system_prompt or None,
        max_tokens=2200,
    )

    # Guardrail intervened -> degrade to a safe, routing packet (TENETS §2).
    if res.intervened:
        return h.response(
            200,
            {
                "session_id": session_id,
                "packet": _safe_packet(),
                "legal_aid_options": h.legal_aid_options(),
                "pdf_url": None,
                "latency_ms": round(h.monotonic_ms() - started),
            },
        )

    # --- 4. assemble -----------------------------------------------------
    packet = _normalize_packet(h.extract_json(res.text) or {}, res.text)
    return h.response(
        200,
        {
            "session_id": session_id,
            "packet": packet,
            "legal_aid_options": h.legal_aid_options(),
            # pdf_url is null in v1 — iOS renders the Markdown locally
            # (API_CONTRACT.md § POST /scan/packet).
            "pdf_url": None,
            "latency_ms": round(h.monotonic_ms() - started),
            "cost_estimate_usd": h.estimate_cost(text_model, res.usage),
        },
    )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _load_document(session_id, document_id):
    """Return (image_bytes, fmt) for the scanned document, or raise _NotFound."""
    for ext, fmt in (("jpg", "jpeg"), ("jpeg", "jpeg"), ("png", "png")):
        try:
            data = h.s3_get(f"{session_id}/{document_id}.{ext}")
            return data, fmt
        except Exception:  # noqa: BLE001 - try the next extension
            continue
    raise _NotFound("document_id not found or expired (>1h old)")


def _normalize_packet(raw: dict, raw_text: str) -> dict:
    """Map a model packet object onto the API_CONTRACT `packet` shape."""
    deadline = raw.get("your_deadline") or {}
    if not isinstance(deadline, dict):
        deadline = {}
    return {
        "title_es": raw.get("title_es") or "Paquete de preparación",
        "what_this_says_es": raw.get("what_this_says_es")
        or (raw_text.strip() if not raw else ""),
        "your_deadline": {
            "date": deadline.get("date"),
            "label_es": deadline.get("label_es") or "Verifica la fecha con la corte.",
        },
        "documents_to_gather_es": _as_list(raw.get("documents_to_gather_es")),
        "extension_request_template": raw.get("extension_request_template") or "",
        "legal_aid_phone_script_es": raw.get("legal_aid_phone_script_es")
        or _DEFAULT_PHONE_SCRIPT,
        "questions_for_lawyer_es": _as_list(raw.get("questions_for_lawyer_es")),
        "cover_sheet_es": raw.get("cover_sheet_es") or _DEFAULT_COVER_SHEET,
    }


def _as_list(value) -> list:
    if isinstance(value, list):
        return [str(v) for v in value if v]
    if isinstance(value, str) and value.strip():
        return [value.strip()]
    return []


_DEFAULT_PHONE_SCRIPT = (
    "Hola, mi nombre es ___. Recibí un documento de inmigración y necesito ayuda. "
    "¿Cuándo puedo tener una consulta gratis?"
)

_DEFAULT_COVER_SHEET = (
    "Lleva este paquete a tu cita con ayuda legal gratis. Tu abogado va a escribir "
    "la respuesta oficial. Este paquete te ayuda a llegar preparado."
)


def _safe_packet() -> dict:
    """A packet that contains no document-derived claims — used when the
    Guardrail intervenes. It still routes the user to a human (TENETS §2)."""
    return {
        "title_es": "Paquete de preparación",
        "what_this_says_es": (
            "No pudimos generar un resumen seguro de este documento. Por tu "
            "seguridad, lleva el documento original directamente a un servicio "
            "de ayuda legal gratis — ellos pueden revisarlo contigo."
        ),
        "your_deadline": {
            "date": None,
            "label_es": "Verifica cualquier fecha directamente con la corte.",
        },
        "documents_to_gather_es": [
            "El documento original que recibiste",
            "Una identificación",
            "Cualquier papel de inmigración que tengas",
        ],
        "extension_request_template": "",
        "legal_aid_phone_script_es": _DEFAULT_PHONE_SCRIPT,
        "questions_for_lawyer_es": [
            "¿Qué significa este documento en mi caso?",
            "¿Qué evidencia debería juntar antes de la próxima cita?",
            "¿Necesito hacer algo antes de alguna fecha límite?",
        ],
        "cover_sheet_es": _DEFAULT_COVER_SHEET,
    }
