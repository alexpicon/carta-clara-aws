"""Shared helpers for Carta Clara Lambda handlers.

CANONICAL SOURCE: backend/src/_shared/helpers.py

This file is *vendored* (copied verbatim) into each handler directory:
    backend/src/scan/helpers.py
    backend/src/ask/helpers.py
    backend/src/refusal_log/helpers.py

Why copy instead of import a sibling package?  SAM packages every function
from its own ``CodeUri`` (``src/scan/``, ``src/ask/``, ``src/refusal_log/``).
A function cannot import ``src/_shared/`` at runtime because that directory is
not inside its deployment artifact. Vendoring keeps one logical source of
truth while guaranteeing ``sam build && sam deploy`` works with the existing
template (no Lambda layer, no template change required).

To change shared logic: edit THIS file, then re-vendor:
    for d in scan ask refusal_log; do cp src/_shared/helpers.py src/$d/helpers.py; done

Design notes:
- Nothing here touches AWS at import time. boto3 clients are created lazily so
  the module imports cleanly under pytest without credentials.
- Every Bedrock call goes through ``converse()``, which attaches the Guardrail
  whenever one is configured (env GUARDRAIL_ID != "PLACEHOLDER").
"""

import json
import os
import re
import time

import boto3

# ---------------------------------------------------------------------------
# Environment (read lazily, defaulted so import never raises)
# ---------------------------------------------------------------------------


def env(name: str, default: str = "") -> str:
    return os.environ.get(name, default)


def region() -> str:
    return env("BEDROCK_REGION", "us-west-2")


def guardrail_id() -> str:
    return env("GUARDRAIL_ID", "PLACEHOLDER")


def guardrail_version() -> str:
    return env("GUARDRAIL_VERSION", "DRAFT")


def guardrail_configured() -> bool:
    gid = guardrail_id()
    return bool(gid) and gid != "PLACEHOLDER"


def kb_id() -> str:
    return env("KNOWLEDGE_BASE_ID", "PLACEHOLDER")


def kb_configured() -> bool:
    k = kb_id()
    return bool(k) and k != "PLACEHOLDER"


# ---------------------------------------------------------------------------
# Lazy boto3 clients (cached). Tests clear ``_CLIENTS`` and patch ``boto3``.
# ---------------------------------------------------------------------------

_CLIENTS: dict = {}


def client(service: str):
    if service not in _CLIENTS:
        _CLIENTS[service] = boto3.client(service, region_name=region())
    return _CLIENTS[service]


def resource(service: str):
    key = "resource:" + service
    if key not in _CLIENTS:
        _CLIENTS[key] = boto3.resource(service, region_name=region())
    return _CLIENTS[key]


def reset_clients() -> None:
    """Test hook — drop cached clients so a fresh mock can be installed."""
    _CLIENTS.clear()


# ---------------------------------------------------------------------------
# HTTP response builder (API Gateway HTTP API proxy format)
# ---------------------------------------------------------------------------

_CORS_HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "*",
}


def response(status: int, body: dict) -> dict:
    return {
        "statusCode": status,
        "headers": dict(_CORS_HEADERS),
        "body": json.dumps(body, ensure_ascii=False),
    }


def parse_body(event: dict) -> dict:
    """Decode an API Gateway event body to a dict. Never raises."""
    raw = event.get("body")
    if raw is None or raw == "":
        return {}
    if isinstance(raw, dict):
        return raw
    try:
        return json.loads(raw)
    except (ValueError, TypeError):
        return {}


# ---------------------------------------------------------------------------
# Prompt loader
# ---------------------------------------------------------------------------
# Prompts are authored by Sage in backend/prompts/. At deploy time they must be
# vendored into the handler's CodeUri (same packaging constraint as helpers.py).
# The loader searches several locations and falls back to a built-in safe
# prompt so handlers + smoke tests work even before Sage's files land.

_PROMPT_SEARCH = [
    # 1. vendored alongside the handler (deploy artifact)
    lambda name: os.path.join(os.path.dirname(__file__), "prompts", name),
    # 2. backend/src/prompts/
    lambda name: os.path.join(os.path.dirname(__file__), "..", "prompts", name),
    # 3. backend/prompts/ (Sage's directory — local dev / pytest)
    lambda name: os.path.join(os.path.dirname(__file__), "..", "..", "prompts", name),
    # 4. explicit override
    lambda name: os.path.join(env("PROMPTS_DIR", "/nonexistent"), name),
]


def load_prompt(name: str, fallback: str = "") -> str:
    """Load a prompt file by name (e.g. 'extraction_prompt.md').

    Returns the file contents if found and non-empty, otherwise ``fallback``.
    Logging the miss helps Sage/Koda see un-wired prompts during integration.
    """
    for resolver in _PROMPT_SEARCH:
        path = resolver(name)
        try:
            with open(path, "r", encoding="utf-8") as fh:
                content = fh.read().strip()
            if content:
                return content
        except (OSError, IOError):
            continue
    print(json.dumps({"level": "warn", "msg": "prompt_not_found", "prompt": name}))
    return fallback


# ---------------------------------------------------------------------------
# JSON extraction from model output
# ---------------------------------------------------------------------------


def extract_json(text: str):
    """Pull the first JSON object out of a model response. Returns dict or None.

    Handles three model output shapes:
      1. Pure JSON (json.loads on the whole stripped text)
      2. ```json ... ``` markdown-fenced (strip the fence, then parse)
      3. Prose containing a `{ ... }` block (find balanced braces, then parse)
    Each pass falls through to the next on parse failure.
    """
    if not text:
        return None

    # Strip a leading/trailing markdown fence if the whole response is fenced.
    # Greedy match — fenced content can contain nested braces.
    fenced = re.search(r"```(?:json)?\s*([\s\S]+?)\s*```", text)
    body = fenced.group(1) if fenced else text
    body = body.strip()

    # Strategy 1: parse the whole body directly.
    try:
        return json.loads(body)
    except (ValueError, TypeError):
        pass

    # Strategy 2: walk braces to find the first balanced { ... } block.
    start = body.find("{")
    if start == -1:
        return None
    depth = 0
    for i in range(start, len(body)):
        if body[i] == "{":
            depth += 1
        elif body[i] == "}":
            depth -= 1
            if depth == 0:
                try:
                    return json.loads(body[start : i + 1])
                except (ValueError, TypeError):
                    return None
    return None


# ---------------------------------------------------------------------------
# Bedrock — Converse API (unified for Claude multimodal/text + Nova fast path)
# ---------------------------------------------------------------------------


class ConverseResult:
    """Outcome of a Bedrock Converse call."""

    def __init__(self, text, stop_reason, blocked_topics, usage, raw):
        self.text = text
        self.stop_reason = stop_reason
        self.blocked_topics = blocked_topics  # list[str] of guardrail topic names
        self.usage = usage  # {"inputTokens": n, "outputTokens": n}
        self.raw = raw

    @property
    def intervened(self) -> bool:
        return self.stop_reason == "guardrail_intervened" or bool(self.blocked_topics)


def text_block(text: str) -> dict:
    return {"text": text}


def image_block(image_bytes: bytes, fmt: str) -> dict:
    """fmt is 'jpeg' or 'png'."""
    return {"image": {"format": fmt, "source": {"bytes": image_bytes}}}


def textract_detect_text(image_bytes: bytes) -> str:
    """OCR an image with Amazon Textract; return text concatenated by line.

    Textract is the primary text-extraction path for /scan — much cheaper and
    faster than asking a multimodal LLM to read pixels, and more reliable for
    pure text. Semantic structuring (which date is the hearing date, etc.)
    still happens in Claude downstream — Textract just gives it clean text.
    """
    resp = client("textract").detect_document_text(Document={"Bytes": image_bytes})
    lines = [
        b.get("Text", "")
        for b in resp.get("Blocks", [])
        if b.get("BlockType") == "LINE" and b.get("Text")
    ]
    return "\n".join(lines)


def converse(model_id, content_blocks, system=None, max_tokens=1500, temperature=0.2):
    """Invoke a Bedrock model via the Converse API with the Guardrail attached.

    The Guardrail is attached to EVERY invocation whenever one is configured
    (TENETS.md §8 — the architecture is the trust story). When GUARDRAIL_ID is
    still the 'PLACEHOLDER' default (pre-console-setup), the call proceeds
    without it and logs a warning so the gap is visible.
    """
    kwargs = {
        "modelId": model_id,
        "messages": [{"role": "user", "content": content_blocks}],
        "inferenceConfig": {"maxTokens": max_tokens, "temperature": temperature},
    }
    if system:
        kwargs["system"] = [{"text": system}]
    if guardrail_configured():
        kwargs["guardrailConfig"] = {
            "guardrailIdentifier": guardrail_id(),
            "guardrailVersion": guardrail_version(),
            "trace": "enabled",
        }
    else:
        print(json.dumps({"level": "warn", "msg": "guardrail_not_configured"}))

    resp = client("bedrock-runtime").converse(**kwargs)

    text = ""
    for block in resp.get("output", {}).get("message", {}).get("content", []):
        if "text" in block:
            text += block["text"]

    return ConverseResult(
        text=text,
        stop_reason=resp.get("stopReason"),
        blocked_topics=_blocked_topics(resp.get("trace", {})),
        usage=resp.get("usage", {}),
        raw=resp,
    )


def _blocked_topics(trace: dict) -> list:
    """Extract guardrail denied-topic names that were BLOCKED, from a Converse trace."""
    names: list = []
    guard = (trace or {}).get("guardrail", {})
    assessments = []
    inp = guard.get("inputAssessment", {})
    for v in inp.values():
        assessments.append(v)
    out = guard.get("outputAssessments", {})
    for v in out.values():
        if isinstance(v, list):
            assessments.extend(v)
        else:
            assessments.append(v)
    for a in assessments:
        for topic in (a.get("topicPolicy", {}) or {}).get("topics", []):
            if topic.get("action") == "BLOCKED" and topic.get("name"):
                names.append(topic["name"])
    return names


# ---------------------------------------------------------------------------
# Bedrock Knowledge Base retrieval
# ---------------------------------------------------------------------------


def kb_retrieve(query_text: str, max_results: int = 4) -> list:
    """Retrieve grounding chunks from the Bedrock Knowledge Base.

    Returns a list of {'text', 'kb_chunk_id', 'source_uri'}. Empty list if the
    KB is not configured yet (pre-console-setup) or the call fails — callers
    degrade gracefully rather than failing the request.
    """
    if not kb_configured():
        return []
    try:
        resp = client("bedrock-agent-runtime").retrieve(
            knowledgeBaseId=kb_id(),
            retrievalQuery={"text": query_text},
            retrievalConfiguration={
                "vectorSearchConfiguration": {"numberOfResults": max_results}
            },
        )
    except Exception as exc:  # noqa: BLE001 - degrade gracefully
        print(json.dumps({"level": "warn", "msg": "kb_retrieve_failed", "error": str(exc)}))
        return []

    chunks = []
    for i, r in enumerate(resp.get("retrievalResults", [])):
        loc = r.get("location", {})
        uri = (
            loc.get("s3Location", {}).get("uri")
            or loc.get("webLocation", {}).get("url")
            or ""
        )
        chunks.append(
            {
                "text": r.get("content", {}).get("text", ""),
                "kb_chunk_id": r.get("metadata", {}).get("x-amz-bedrock-kb-chunk-id")
                or f"chunk-{i + 1}",
                "source_uri": uri,
            }
        )
    return chunks


# ---------------------------------------------------------------------------
# S3 helpers — ephemeral upload (TENETS.md §7)
# ---------------------------------------------------------------------------


def s3_put_ephemeral(key: str, data: bytes, content_type: str) -> None:
    """Store an object tagged for ephemeral deletion.

    The ``ephemeral=true`` tag is what the bucket's tag-scoped S3 lifecycle rule
    (``ExpireEphemeralUploads`` in template.yaml) filters on — every object this
    function writes is in scope for deletion. ``ttl=1h`` is informational.
    """
    client("s3").put_object(
        Bucket=env("UPLOADS_BUCKET"),
        Key=key,
        Body=data,
        ContentType=content_type,
        Tagging="ephemeral=true&ttl=1h",
    )


def s3_get(key: str) -> bytes:
    """Fetch an object's bytes. Raises on missing/expired key (caller maps to 404)."""
    obj = client("s3").get_object(Bucket=env("UPLOADS_BUCKET"), Key=key)
    return obj["Body"].read()


def s3_presign(key: str, expires: int = 3600) -> str:
    return client("s3").generate_presigned_url(
        "get_object",
        Params={"Bucket": env("UPLOADS_BUCKET"), "Key": key},
        ExpiresIn=expires,
    )


# ---------------------------------------------------------------------------
# Polly — Spanish audio synthesis
# ---------------------------------------------------------------------------


def synthesize_spanish(text: str) -> bytes:
    """Synthesize Spanish speech with the configured neural Polly voice."""
    return synthesize_speech(text, "es")


# Per-language Polly defaults. Both are neural-engine, both are well-tested
# en-US / es-US voices. Overridable per-language with POLLY_VOICE_EN /
# POLLY_VOICE_ES env vars (and POLLY_VOICE still works as the es fallback).
_POLLY_DEFAULTS = {
    "en": ("Joanna", "en-US"),
    "es": ("Lupe", "es-US"),
}


def synthesize_speech(text: str, language: str = "es") -> bytes:
    """Synthesize speech in the requested language ('en' or 'es')."""
    language = language if language in _POLLY_DEFAULTS else "es"
    default_voice, language_code = _POLLY_DEFAULTS[language]
    voice = env(f"POLLY_VOICE_{language.upper()}", env("POLLY_VOICE", default_voice))
    resp = client("polly").synthesize_speech(
        Text=text,
        OutputFormat="mp3",
        VoiceId=voice,
        Engine="neural",
        LanguageCode=language_code,
    )
    return resp["AudioStream"].read()


# ---------------------------------------------------------------------------
# Cost estimate (rough — for the demo's transparency panel)
# ---------------------------------------------------------------------------

# USD per 1M tokens (approximate public list pricing, May 2026).
_PRICING = {
    "claude": (3.0, 15.0),  # Sonnet class: (input, output)
    "nova": (0.8, 3.2),  # Nova Pro
}


def estimate_cost(model_id: str, usage: dict) -> float:
    inp = usage.get("inputTokens", 0)
    out = usage.get("outputTokens", 0)
    key = "nova" if "nova" in (model_id or "").lower() else "claude"
    pin, pout = _PRICING[key]
    return round((inp * pin + out * pout) / 1_000_000, 6)


# ---------------------------------------------------------------------------
# Refusal taxonomy — maps Guardrail denied-topic names to API_CONTRACT reasons
# ---------------------------------------------------------------------------

# Guardrail topic name (DENIED_TOPICS.md §1) -> API_CONTRACT refusal_reason enum
GUARDRAIL_TOPIC_TO_REASON = {
    "LegalStrategy": "legal_strategy",
    "HearingAttendance": "hearing_attendance",
    "AdmitDenyAllegations": "admit_deny",
    "EligibilityPredictions": "eligibility",
    "OutcomePredictions": "outcome",
    "JudgeBiasClaims": "judge_bias",
    "LawEnforcementScripts": "le_scripts",
    "EvasionInstructions": "evasion",
    "OtherProfessionalAdvice": "other_professional",
    "DocumentAuthenticity": "document_authenticity",
}

# API_CONTRACT refusal_reason enum -> Spanish label shown in the refusal-log UI
REASON_LABEL_ES = {
    "legal_strategy": "Estrategia legal",
    "hearing_attendance": "Decisiones sobre asistir a la corte",
    "admit_deny": "Admitir o negar acusaciones",
    "eligibility": "Predicción de elegibilidad",
    "outcome": "Predicción del resultado del caso",
    "judge_bias": "Opinión sobre el juez",
    "le_scripts": "Qué decir a las autoridades",
    "evasion": "Cómo evadir a las autoridades",
    "other_professional": "Consejo médico, fiscal o financiero",
    "document_authenticity": "Si un documento o persona es fraude",
    "other": "Tema fuera del alcance de la aplicación",
}


def reason_from_topics(blocked_topics: list) -> str:
    """Pick a single API_CONTRACT refusal_reason from blocked Guardrail topics."""
    for topic in blocked_topics or []:
        if topic in GUARDRAIL_TOPIC_TO_REASON:
            return GUARDRAIL_TOPIC_TO_REASON[topic]
    return "other"


def reason_label_es(reason: str) -> str:
    return REASON_LABEL_ES.get(reason, REASON_LABEL_ES["other"])


# ---------------------------------------------------------------------------
# Safe-replacement text + legal aid (TENETS.md §2 — refuse, then route)
# ---------------------------------------------------------------------------

# Default Spanish safe-replacement text (DENIED_TOPICS.md §2). The Guardrail
# also returns its own configured message; this is the fallback.
DEFAULT_REFUSAL_ES = (
    "No puedo ayudarte con estrategia legal. Sí puedo explicarte el documento "
    "que subiste, resumir lo que dice, identificar fechas importantes y "
    "ayudarte a preparar preguntas para un abogado de inmigración. Para tu "
    "pregunta específica, por favor contacta un servicio de ayuda legal "
    "gratis — ellos pueden responder de manera segura y confidencial."
)

# Seattle free legal aid clinics (hard-coded for v1 — see RIKU-13 / SAGE-09).
# Phone numbers are public main lines; the app instructs users to call to
# confirm hours and request a free consultation.
LEGAL_AID_OPTIONS = [
    {
        "name": "Northwest Immigrant Rights Project (NWIRP)",
        "phone": "+1-206-587-4009",
        "address": "615 Second Ave, Suite 400, Seattle, WA 98104",
        "hours": "Lun–Vie 9:00–17:00",
        "languages": ["Español", "English"],
        "free": True,
    },
    {
        "name": "Colectiva Legal del Pueblo",
        "phone": "+1-206-902-5283",
        "address": "PO Box 4093, Tukwila, WA 98138",
        "hours": "Lun–Vie 9:00–17:00",
        "languages": ["Español", "English"],
        "free": True,
    },
    {
        "name": "Refugee Women's Alliance (ReWA)",
        "phone": "+1-206-721-0243",
        "address": "4008 Martin Luther King Jr Way S, Seattle, WA 98108",
        "hours": "Lun–Vie 9:00–17:00",
        "languages": ["Español", "English", "+ otros"],
        "free": True,
    },
]


def legal_aid_options() -> list:
    """Return a fresh copy of the legal aid list (callers may mutate responses)."""
    return [dict(o) for o in LEGAL_AID_OPTIONS]


# ---------------------------------------------------------------------------
# Two-layer refusal resolution (defense in depth)
# ---------------------------------------------------------------------------

# Valid API_CONTRACT refusal_reason values: the 10 denied topics + "other".
VALID_REFUSAL_REASONS = set(REASON_LABEL_ES)


def resolve_refusal(res):
    """Decide whether a Converse result is a refusal — from EITHER of two layers.

    Layer 1 — Bedrock Guardrail: ``res.intervened`` is True when the Guardrail
    blocked the request. Strong, enforced, cannot be jailbroken — but only
    active once GUARDRAIL_ID is configured (not the 'PLACEHOLDER' default).

    Layer 2 — prompt-instructed fallback: the model is told to self-report a
    refusal as JSON — ``{"refused": true, "refusal_reason": "<enum>",
    "refusal_text_es": "..."}``. This keeps refusals — and the visible refusal
    counter — working even while the Guardrail is not yet configured.

    Layer 1 wins when both fire. Returns a 4-tuple:
      (refused: bool,
       reason: str | None,            # API_CONTRACT refusal_reason enum
       refusal_text_es: str | None,   # Spanish safe-replacement text
       source: str | None)           # "guardrail" | "prompt" — log/eval only
    """
    # Layer 1 — Guardrail interception.
    if res.intervened:
        reason = reason_from_topics(res.blocked_topics)
        text = (res.text or "").strip() or DEFAULT_REFUSAL_ES
        return True, reason, text, "guardrail"

    # Layer 2 — model self-reported a refusal in its JSON output.
    data = extract_json(res.text) or {}
    if data.get("refused") is True:
        reason = data.get("refusal_reason")
        if reason not in VALID_REFUSAL_REASONS:
            reason = "other"
        text = (data.get("refusal_text_es") or "").strip() or DEFAULT_REFUSAL_ES
        return True, reason, text, "prompt"

    return False, None, None, None


# ---------------------------------------------------------------------------
# Misc
# ---------------------------------------------------------------------------


def now_iso() -> str:
    from datetime import datetime, timezone

    return datetime.now(timezone.utc).isoformat()


def monotonic_ms() -> float:
    return time.monotonic() * 1000.0
