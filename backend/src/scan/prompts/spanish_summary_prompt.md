# Carta Clara — Document Summary & Sections Prompt

> Contract
> - PREPEND: backend/prompts/system_prompt.md
> - INPUT (substituted by the Lambda before invocation):
>   - `{{EXTRACTION_JSON}}` — the JSON object produced by extraction_prompt.md
>   - `{{READING_LEVEL}}` — one of: `beginner` | `intermediate` | `full`
>   - `{{KB_CHUNKS}}` — retrieved Knowledge Base chunks (may be empty)
> - OUTPUT: a single JSON object, no prose, no markdown fences. Supplies the
>   `summary_en`, `summary_es`, `sections`, and `urgency` fields of the POST /scan
>   response in docs/API_CONTRACT.md.
> - Koda parses this with `json.loads()`.

---

## Goal

The user is reading an English government document that scares them. They may
have low English proficiency or low literacy in any language. Our job is to
turn the EXTRACTED FACTS into a **specific, concrete explanation of THIS
document** — not a generic explanation of "documents like this."

## STRICT REQUIREMENTS — read these before writing anything

### 1. The headline summary is structured

`summary_es` (and `summary_en`) is **2–3 sentences**, no more. It must answer:

1. **WHO sent this** — name the agency from `issuing_agency`.
2. **WHY it was sent** — paraphrase `alleged_basis_summary` if present; otherwise name the document type.
3. **WHAT the user must do next, and by when** — use `deadline_critical` or `hearing_date`. If neither exists, say "no deadline is listed."

**BAD (forbidden — too generic):**

> "This is a notice from the government about your immigration case. It is important to understand and respond appropriately."

**GOOD (required style):**

> "USCIS sent you a Request for Evidence about your I-485 application. They want more proof of your marriage. You have until **November 15, 2026** to respond."

> "ICE issued a Notice to Appear (Form I-862). The government alleges you overstayed your B-2 visa. Your immigration court hearing is **October 15, 2026 at 9:00 AM** at the Seattle Immigration Court."

### 2. Mandatory sections (produce all that apply)

For every `EXTRACTION_JSON` field with content, produce a corresponding section.
Skip a section only if its underlying facts are all `null`.

| Section title (en / es)                                  | Required when…                            | Must mention (quote verbatim)                                  |
|----------------------------------------------------------|-------------------------------------------|----------------------------------------------------------------|
| **Who sent this and why** / Quién envió esto y por qué    | `issuing_agency` present                  | The agency name; the document type; `issuing_officer` if known. |
| **What they specifically say** / Lo que dicen exactamente | `alleged_basis_summary` or `charges_cited`| Paraphrase `alleged_basis_summary`; list each entry from `charges_cited` and explain in plain words what the statute is about. |
| **Your key dates** / Tus fechas importantes              | `hearing_date` OR `deadline_critical` set | Each date, its time if known, and what it means. NEVER just say "the date in the document" — name the actual date. |
| **Where you need to go** / Adónde tienes que ir          | `court_name` set                          | The court name and full `court_address`. |
| **What is NOT decided yet** / Lo que TODAVÍA no se decidió | Always (informational)                  | Be specific to the document type — for an NTA: "no removal order has been issued yet"; for an RFE: "no decision has been made on your case yet". |
| **Your rights at this stage** / Tus derechos en esta etapa | Always                                  | Right to a lawyer; right to a free interpreter in immigration court; right to bring a witness. Information only. |

You may add extra sections beyond these if the document warrants them, but the
mandatory ones above must be present whenever their trigger is met.

### 3. Specificity rule — the test for every sentence

Before writing any section body, ask: **does this sentence contain a specific
value from EXTRACTION_JSON or KB_CHUNKS?** If the answer is no, the sentence is
too generic — rewrite it with a quoted date, agency name, statute, country, or
court address.

The acceptable exception is the "Your rights at this stage" section, which is
informational and may be document-type-general.

### 4. Reading-level slider — `{{READING_LEVEL}}`

Controls `summary_es` and each `section_body_es` complexity. NEVER changes
facts, only how they are phrased.

- `beginner` — 5th-grade reading level. Very short sentences. Everyday words.
  No legal terms unless defined in parentheses immediately. Default and safest.
- `intermediate` — adult conversational. Short paragraphs OK. Common legal
  terms may appear if defined once.
- `full` — full-detail. Complete explanation, statute names used with plain
  definitions. Still warm and clear.

`section_body_full_es` is ALWAYS written at `full` detail regardless of the
slider, so the iOS slider can expand a card to maximum detail without another
API call.

### 5. Urgency object

Build from `deadline_critical` / `hearing_date`:

- `is_urgent` — `true` if any future date is present in the extraction.
- `deadline_date` — the ISO date (the soonest if there are several), or `null`.
- `deadline_label_es` — a **specific** Spanish label naming the date:
  - Hearing: `"Fecha de corte: 15 de octubre de 2026, 9:00 AM"`
  - Other deadline: `"Fecha límite: 15 de noviembre de 2026"`
- `verification_note_es` — always remind the user to confirm the date directly
  with the agency, because a photo can be misread:
  `"Confirma esta fecha llamando directamente a la corte. Una foto se puede leer mal."`

## Hard rules

1. **Information, not advice.** Explain what the document says, what is
   urgent, who is named, what categories of evidence/questions exist. Never
   say what to argue, whether to attend, whether to admit/deny, whether the
   user qualifies for relief, or what will happen.
2. **Do not minimize or inflate.** A removal proceeding is serious — say so
   calmly. But always state plainly when something is NOT a final decision.
3. **Grounding.** Every claim comes from `EXTRACTION_JSON` or `KB_CHUNKS`.
   Never invent dates, names, statutes, or consequences. If
   `extraction_confidence` is `low` or a needed field is `null`, say so in
   the relevant section ("this part could not be read clearly — verify with
   the agency").
4. **PII.** Redaction tokens stay redacted. Never reconstruct a name or
   A-number.
5. Every section explanation, and the summary, ends pointing the user toward
   the same next step: free legal aid.

## Output schema (return EXACTLY this — no prose, no markdown)

```json
{
  "summary_en": "string — 2-3 sentences following the structured pattern above",
  "summary_es": "string — same structure, in Spanish (or English if LANGUAGE OVERRIDE)",
  "sections": [
    {
      "section_title_en": "string",
      "section_title_es": "string",
      "section_body_es": "string — at requested reading level, MUST quote specific extracted facts",
      "section_body_full_es": "string — same explanation at full detail",
      "citation_ids": ["string"]
    }
  ],
  "urgency": {
    "is_urgent": true,
    "deadline_date": "YYYY-MM-DD or null",
    "deadline_label_es": "string — names the actual date, not 'a date'",
    "verification_note_es": "string"
  }
}
```

Return only the JSON object.
