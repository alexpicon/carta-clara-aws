# Carta Clara — Response Preparation Packet Prompt

> **Contract.**
> - PREPEND: [`system_prompt.md`](./system_prompt.md)
> - INPUT (substituted by the Lambda before invocation):
>   - `{{EXTRACTION_JSON}}` — the JSON object from `extraction_prompt.md`
>   - `{{SUMMARY_JSON}}` — the JSON object from `spanish_summary_prompt.md`
>   - `{{KB_CHUNKS}}` — retrieved KB chunks (legal-aid directory + EOIR
>     Practice Manual). Each chunk has `id`, `source_label`, and text.
> - OUTPUT: a single JSON object — no prose, no Markdown fences. Supplies
>   the `packet` object of the `/scan/packet` response in
>   [`docs/API_CONTRACT.md`](../../docs/API_CONTRACT.md).
> - All string values are plain text (system prompt's Formatting rule
>   applies). The iOS app handles all visual styling.
> - The handler parses with `json.loads()`.

---

## Task

Build the content of a **Response Preparation Packet** — a printable document
the user carries to a free legal-aid appointment. The packet helps the user
arrive **prepared**. It never replaces the lawyer and never speaks to the
government.

## Bright line

The packet is preparation material for a human lawyer. It must **not**
contain:

- A drafted substantive response, motion, or pleading to USCIS, EOIR, ICE,
  DHS, or any court.
- A statement of what to admit, deny, argue, or claim.
- A prediction of eligibility or outcome.
- A recommendation about whether to attend the hearing.

Everything in the packet is one of: (a) a neutral restatement of what the
document says, (b) a generic checklist or question list, or (c) a blank
fill-in template the user completes **with** their lawyer. The cover sheet
states plainly that the lawyer writes the official response.

## Field-by-field instructions

| Field | What goes in |
|---|---|
| `title_es` | A short title in the chosen language. Spanish example: *"Paquete de preparación para tu cita de ayuda legal"*. |
| `what_this_says_es` | One plain-language paragraph restating what the document says. Source: `{{SUMMARY_JSON}}` / `{{EXTRACTION_JSON}}` only. Simple sentences. |
| `your_deadline` | `{ "date": ISO date or null, "label_es": string }` from the extraction's critical date. e.g. *"Fecha de corte: 15 de octubre de 2026, 9:00 AM, Seattle Immigration Court, 1000 Second Avenue, Suite 2900, Seattle, WA 98104."* |
| `documents_to_gather_es` | Generic evidence/identity checklist as a string array. Generic categories only (identity document, prior immigration paperwork, proof of time in the U.S., proof of family ties, relevant medical records, character references). Do not tailor to argue a theory of the case. |
| `extension_request_template` | **Always return `""`** (empty string). The field is retained only for backward compatibility with the iOS Codable model; iOS no longer renders it. Providing an extension-letter template — even with disclaimers — implies a procedural recommendation, which is too close to legal advice. The lawyer decides. |
| `legal_aid_phone_script_es` | A short script for calling a legal-aid intake line. Model on the NTA demo: *"Hola, mi nombre es ____. Recibí un Notice to Appear con fecha de corte el ____. Necesito ayuda. ¿Cuándo puedo tener una consulta gratis?"* |
| `questions_for_lawyer_es` | String array of questions the user should **ask** the lawyer. (Asking is allowed; answering is not.) Examples: *"¿Qué significa esta acusación en mi caso?", "¿Qué tipos de evidencia debería juntar antes de la próxima cita?", "¿Necesito hacer algo antes de la fecha límite?", "¿Hay formas de pedir más tiempo si las necesito?", "¿Qué pasa si no entiendo algo en la corte?"*. |
| `cover_sheet_es` | A short sentence in the chosen language. Spanish: *"Lleva este paquete a tu cita con ayuda legal gratis. Tu abogado va a escribir la respuesta oficial. Este paquete te ayuda a llegar preparado."* |

## Grounding & safety

- Use only facts from `{{EXTRACTION_JSON}}`, `{{SUMMARY_JSON}}`, and
  `{{KB_CHUNKS}}`. Never invent dates, addresses, phone numbers, or statutes.
- If the critical date or court address is `null`/uncertain, leave a `____`
  blank in the template and tell the user (in their language) to confirm it
  with the court.
- Keep all output at a plain, warm, 5th-grade reading level.
- The packet ends pointing the user to free legal aid. The Lambda appends the
  `legal_aid_options` list from the KB — do not invent clinics here.

## Output schema

```json
{
  "title_es": "string (plain text)",
  "what_this_says_es": "string (plain text, paragraph breaks via \\n\\n)",
  "your_deadline": { "date": "YYYY-MM-DD or null", "label_es": "string (plain text)" },
  "documents_to_gather_es": ["string (plain text)"],
  "extension_request_template": "",
  "legal_aid_phone_script_es": "string (plain text)",
  "questions_for_lawyer_es": ["string (plain text)"],
  "cover_sheet_es": "string (plain text)"
}
```

Return only the JSON object.
