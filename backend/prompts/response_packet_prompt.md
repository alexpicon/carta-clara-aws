# Carta Clara — Response Preparation Packet Prompt

> Contract
> - PREPEND: backend/prompts/system_prompt.md
> - INPUT (substituted by the Lambda before invocation):
>   - `{{EXTRACTION_JSON}}` — the JSON object from extraction_prompt.md
>   - `{{SUMMARY_JSON}}` — the JSON object from spanish_summary_prompt.md
>   - `{{KB_CHUNKS}}` — retrieved KB chunks, especially legal-aid directory and
>     EOIR Practice Manual chunks (each with `id`, `source_label`, text).
> - OUTPUT: a single JSON object, no prose, no markdown fences. Supplies the
>   `packet` object of the POST /scan/packet response in docs/API_CONTRACT.md.
> - **String fields are PLAIN TEXT — no Markdown syntax of any kind.** Do
>   NOT use `**bold**`, `*italic*`, `# headings`, `> blockquotes`, `---`
>   dividers, backticks, or bullet markers. iOS renders these as raw
>   characters (e.g. `**Form I-246**` shows up on screen with the asterisks
>   visible) which looks broken. Use plain Spanish prose with paragraph
>   breaks (`\n\n`). The iOS app applies its own typography/styling.
> - Koda parses this with `json.loads()`.

---

## Task

Build the content of a **Response Preparation Packet** — a printable document the
user carries to a free legal-aid appointment. The packet helps the user arrive
PREPARED. It never replaces the lawyer and never speaks to the government.

## The bright line for this packet (read twice)

The packet is preparation material for a human lawyer. It MUST NOT contain:

- A drafted substantive response, answer, motion, or pleading to USCIS, EOIR, ICE,
  DHS, or any court.
- Any statement of what to admit, deny, argue, or claim.
- Any prediction of eligibility or outcome.
- Any recommendation about whether to attend the hearing.

Everything in the packet is either (a) a neutral restatement of what the document
says, (b) a generic checklist/question list, or (c) a blank fill-in template the
user completes WITH their lawyer. The cover sheet states plainly that the lawyer
writes the official response.

## Field-by-field instructions

- `title_es` — e.g. "Paquete de preparación para tu cita de ayuda legal".
- `what_this_says_es` — one plain-Spanish paragraph (NO Markdown, no asterisks
  for emphasis) restating what the document says, drawn only from
  `{{SUMMARY_JSON}}`/`{{EXTRACTION_JSON}}`. Use simple sentences. If you want
  to emphasize a term, just write it normally — the iOS app handles styling.
- `your_deadline` — `{ "date": ISO date or null, "label_es": "..." }` from the
  extraction's critical date, e.g. "Fecha de corte: 15 de octubre de 2026, 9:00 AM,
  Seattle Immigration Court, 1000 Second Avenue, Suite 2900, Seattle, WA 98104".
- `documents_to_gather_es` — generic evidence/identity checklist as a string array.
  Generic categories only (e.g. identity document, prior immigration paperwork,
  proof of time in the U.S., proof of family ties, relevant medical records,
  character references). Do NOT tailor the list to argue a theory of the case.
- `extension_request_template` — **always return an empty string `""`**. We
  removed this field from the user-facing packet: providing an extension-letter
  template — even with a "talk to your lawyer first" disclaimer — implies the
  app is recommending a procedural path (asking for more time). That is too
  close to legal strategy advice. The right next step for the user is to talk
  to a free legal-aid attorney; the questions list and phone script handle
  that. Leave this field as `""` for backwards compatibility; iOS no longer
  renders it.
- `legal_aid_phone_script_es` — a short Spanish script for calling a legal-aid
  intake line. Model on the NTA demo:
  "Hola, mi nombre es ____. Recibí un Notice to Appear con fecha de corte el ____.
  Necesito ayuda. ¿Cuándo puedo tener una consulta gratis?"
- `questions_for_lawyer_es` — string array of questions the user should ASK the
  lawyer (asking questions is allowed; answering them is not). Examples:
  "¿Qué significa esta acusación en mi caso?",
  "¿Qué tipos de evidencia debería juntar antes de la próxima cita?",
  "¿Necesito hacer algo antes de la fecha límite?",
  "¿Hay formas de pedir más tiempo si las necesito?",
  "¿Qué pasa si no entiendo algo en la corte?".
- `cover_sheet_es` — exactly this meaning in Spanish: "Lleva este paquete a tu cita
  con ayuda legal gratis. Tu abogado va a escribir la respuesta oficial. Este
  paquete te ayuda a llegar preparado."

## Grounding & safety

- Use only facts from `{{EXTRACTION_JSON}}`, `{{SUMMARY_JSON}}`, and `{{KB_CHUNKS}}`.
  Never invent dates, addresses, phone numbers, or statutes.
- If the critical date or court address is `null`/uncertain, leave a `____` blank in
  the template and say in Spanish that the user must confirm it with the court.
- Keep all Spanish at a plain, warm, 5th-grade reading level.
- The packet ends pointing the user to free legal aid (the Lambda appends the
  `legal_aid_options` list from the KB; do not invent clinics here).

## Output schema (return EXACTLY this — string fields are PLAIN TEXT)

```json
{
  "title_es": "string (plain text)",
  "what_this_says_es": "string (plain text, paragraph breaks via \\n\\n)",
  "your_deadline": { "date": "YYYY-MM-DD or null", "label_es": "string (plain text)" },
  "documents_to_gather_es": ["string (plain text)"],
  "extension_request_template": "" ,
  "legal_aid_phone_script_es": "string (plain text)",
  "questions_for_lawyer_es": ["string (plain text)"],
  "cover_sheet_es": "string (plain text)"
}
```

Return only the JSON object. PLAIN TEXT in all string fields — no Markdown
asterisks, headings, blockquotes, dividers, or backticks. The iOS app handles
all visual styling.
