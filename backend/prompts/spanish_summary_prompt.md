# Carta Clara — Document Summary & Sections Prompt

> Contract
> - PREPEND: backend/prompts/system_prompt.md
> - INPUT (substituted before invocation):
>   - `{{EXTRACTION_JSON}}` — JSON from extraction_prompt.md
>   - `{{READING_LEVEL}}` — `beginner` | `intermediate` | `full`
>   - `{{KB_CHUNKS}}` — KB chunks (may be empty)
> - OUTPUT: a single JSON object. NO markdown fences. NO prose around it.
> - Hard ceiling: total response ≤ 1200 tokens. Brevity is mandatory.

---

## Goal

Turn extracted facts into a **specific, concrete** explanation of THIS
document — never generic. Audience: a Spanish-speaking grandmother or her
helper, reading a frightening English government letter.

## STRICT REQUIREMENTS

### 1. Headline (`summary_es` / `summary_en`) — exactly 2 sentences

Sentence 1: WHO sent it + WHAT it is (use `issuing_agency` and `document_type` verbatim).
Sentence 2: WHAT the user must do next + WHEN (use `deadline_critical` or `hearing_date`; if neither, say "no deadline is listed in this document").

That's it. No third sentence. No "this is important," no "you should call a lawyer" — those go elsewhere.

**BAD:** "This is a notice from the government about your immigration case. It is important to understand and respond appropriately."

**GOOD:** "U.S. Department of Homeland Security sent you a Notice to Appear (Form I-862). No hearing date is listed in this document — contact a free immigration attorney immediately."

### 2. Sections — produce EXACTLY these 4, in this order

Skip a section only if its trigger fields are all `null`.

| section_title_en | section_title_es | Trigger | Must include |
|---|---|---|---|
| **Who sent this** | Quién envió esto | `issuing_agency` set | Agency name; document type; officer title if known. |
| **What they say about you** | Lo que dicen sobre ti | `alleged_basis_summary` OR `charges_cited` non-empty | The allegation in plain words; list EACH `charges_cited` entry verbatim with a one-line plain meaning. |
| **Your key dates** | Tus fechas importantes | `hearing_date` OR `deadline_critical` set | Each date verbatim (YYYY-MM-DD) with what it means. If both null, omit this section. |
| **Your rights now** | Tus derechos ahora | Always | Right to a lawyer, right to a free interpreter in immigration court, right to remain silent in some interactions. Information only, no advice. |

### 2a. EACH section MUST produce two bodies

Per section, write BOTH of these — they feed two different UI states:

- `section_body_es` — **1–2 sentences**, at the requested `{{READING_LEVEL}}`. The Summary/Normal-slider view shows this.
- `section_body_full_es` — **4–6 sentences**, always at FULL detail. This is what the Full-slider view expands to. It MUST contain meaningfully more information than `section_body_es`: more specific facts from EXTRACTION_JSON, what the user can typically expect at this stage of the process, and one extra piece of context a helper would find useful. Same facts, more depth — no advice.

The two bodies must differ. If `section_body_full_es` is just a rephrasing of `section_body_es`, the slider has nothing to switch to — produce real additional content.

### 3. Specificity test

Before writing any sentence, ask: does this sentence contain a specific value
from EXTRACTION_JSON or KB_CHUNKS? If not, rewrite with a quoted date, agency
name, statute, country, or court address. The only acceptable exception is
"Your rights now," which is procedural and document-type-general.

### 4. Reading level — `{{READING_LEVEL}}`

Controls how plain the language is in `section_body_es` and `summary_es`. Same
facts, different wording:
- `beginner` — 5th-grade reading level, short sentences, everyday words, legal terms always defined in parentheses.
- `intermediate` — adult conversational, short paragraphs OK.
- `full` — adult full-detail, legal terms used with brief definitions.

### 5. Urgency object

- `is_urgent`: `true` if any future date in extraction, else `false`.
- `deadline_date`: ISO date string, or `null`.
- `deadline_label_es`: specific label naming the date, e.g. `"Fecha de corte: 15 de octubre de 2026, 9:00 AM"`. If no date, `null`.
- `verification_note_es`: always present, reminds the user to confirm the date with the agency directly. Example: `"Confirma esta fecha llamando directamente a la corte. Una foto se puede leer mal."`

## Hard rules

1. **Information, not advice.** Explain what the document says. Never say what to argue, whether to attend, whether to admit/deny, whether the user qualifies, or what will happen.
2. **Grounding.** Only use values from EXTRACTION_JSON or KB_CHUNKS. Never invent.
3. **Brevity beats completeness.** If you're about to write a third sentence, stop.

## Output schema (return EXACTLY this — NO markdown fences, NO prose)

```
{
  "summary_en": "2 sentences",
  "summary_es": "2 sentences (or English if LANGUAGE OVERRIDE)",
  "sections": [
    {
      "section_title_en": "Who sent this",
      "section_title_es": "Quién envió esto",
      "section_body_es": "1-2 short sentences at requested reading level, specific facts",
      "section_body_full_es": "4-6 sentences with meaningfully MORE detail than body_es — additional facts, what-to-expect context, helper-level depth. Same information, more depth, no advice.",
      "citation_ids": []
    }
  ],
  "urgency": {
    "is_urgent": true,
    "deadline_date": "YYYY-MM-DD or null",
    "deadline_label_es": "string or null",
    "verification_note_es": "string"
  }
}
```

Return the JSON object only. No fences. No commentary. Total output ≤ 1600 tokens.
