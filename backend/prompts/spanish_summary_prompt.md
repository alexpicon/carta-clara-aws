# Carta Clara — Document Summary & Sections Prompt

> **Contract.**
> - PREPEND: [`system_prompt.md`](./system_prompt.md)
> - INPUT (substituted by the Lambda before invocation):
>   - `{{EXTRACTION_JSON}}` — the JSON object from `extraction_prompt.md`
>   - `{{READING_LEVEL}}` — `intermediate` | `full`
>   - `{{KB_CHUNKS}}` — KB chunks (may be empty)
>   - The request's `language` (`es` or `en`) drives which language field gets
>     filled. See **Language fill rule** below.
> - OUTPUT: a single MINIFIED JSON object — no newlines, no indentation, no
>   spaces after `:` or `,`. One line. No Markdown fences. No prose.
> - Hard ceilings: total response ≤ 1300 tokens, sentence length ≤ 20 words.
>   Brevity is mandatory.
> - No bilingual parentheticals inside content. Do not write *"Departamento de
>   Seguridad Nacional (U.S. Department of Homeland Security)"* — write only
>   the language you were asked for. The other-language field is empty.

---

## Goal

Turn extracted facts into a **specific, concrete** explanation of this
document — never generic. Audience: a Spanish-speaking grandmother or her
helper, reading a frightening English government letter.

## Rules

### 1. Headline (`summary_es` / `summary_en`) — exactly 2 sentences

- Sentence 1: **WHO** sent it and **WHAT** it is (use `issuing_agency` and
  `document_type` verbatim).
- Sentence 2: **WHAT** the user must do next and **WHEN** (use
  `deadline_critical` or `hearing_date`; if neither, say *"no deadline is
  listed in this document"*).

No third sentence. No filler ("this is important," "call a lawyer") — those
belong elsewhere.

**BAD:** *"This is a notice from the government about your immigration case.
It is important to understand and respond appropriately."*

**GOOD:** *"U.S. Department of Homeland Security sent you a Notice to Appear
(Form I-862). No hearing date is listed in this document — contact a free
immigration attorney immediately."*

### 2. Sections — produce exactly these 4, in order

Skip a section only if its trigger fields are all `null`.

| `section_title_en` | `section_title_es` | Trigger | Must include |
|---|---|---|---|
| Who sent this | Quién envió esto | `issuing_agency` set | Agency name, document type, officer title if known. |
| What they say about you | Lo que dicen sobre ti | `alleged_basis_summary` or `charges_cited` non-empty | The allegation in plain words; list each `charges_cited` entry verbatim with a one-line plain meaning. |
| Your key dates | Tus fechas importantes | `hearing_date` or `deadline_critical` set | Each date verbatim (YYYY-MM-DD) with what it means. Omit the section if both null. |
| Your rights now | Tus derechos ahora | Always | Right to a lawyer, right to a free interpreter in immigration court, right to remain silent in some interactions. Information only, no advice. |

### 3. Each section produces two bodies

- `section_body_es` — **2–3 sentences** at the requested `{{READING_LEVEL}}`.
  The first sentence must stand on its own as a complete summary; sentences
  2–3 add detail. (The iOS Sencillo view trims to the first sentence
  client-side.)
- `section_body_full_es` — **4–5 sentences**, always at full detail. Must
  contain meaningfully more than `section_body_es`: more facts from
  `{{EXTRACTION_JSON}}`, what the user can typically expect at this stage,
  one extra piece of context a helper would find useful. Same facts, more
  depth — never advice.

The two bodies must differ. If `section_body_full_es` only rephrases
`section_body_es`, the reading-level toggle has nothing to switch to.

### 4. Specificity test

Before writing any sentence, ask: does it contain a specific value from
`{{EXTRACTION_JSON}}` or `{{KB_CHUNKS}}`? If not, rewrite with a quoted
date, agency name, statute, country, or court address. The only exception
is *Your rights now*, which is procedural and document-type-general.

### 5. Reading level — `{{READING_LEVEL}}`

Controls how plain the language is in `section_body_es` and `summary_es`:

- `intermediate` — adult conversational; short paragraphs OK.
- `full` — adult full-detail; legal terms used with brief inline definitions.

### 6. Urgency object

- `is_urgent` — `true` if any future date appears in extraction; else `false`.
- `deadline_date` — ISO date string, or `null`.
- `deadline_label_es` — specific label naming the date, e.g. *"Fecha de
  corte: 15 de octubre de 2026, 9:00 AM"*. `null` if no date.
- `verification_note_es` — always present, reminds the user to confirm the
  date with the agency directly. e.g. *"Confirma esta fecha llamando
  directamente a la corte. Una foto se puede leer mal."*

## Output schema

Return a single minified JSON line:

```
{"summary_en":"…","summary_es":"…","sections":[{"section_title_en":"…","section_title_es":"…","section_body_es":"…","section_body_full_es":"…","citation_ids":[]}],"urgency":{"is_urgent":bool,"deadline_date":"YYYY-MM-DD|null","deadline_label_es":"…|null","verification_note_es":"…"}}
```

## Language fill rule (token saver — mandatory)

The field name suffixes (`_es`, `_en`) are historical. **Fill only one
language per response.**

- Request `language=es` (default): fill `summary_es` and section bodies with
  Spanish. Set `summary_en` to `""`.
- Request `language=en`: fill `summary_en` with English. Set `summary_es` to
  `""`. Section bodies are written in English even though the field name ends
  `_es`. The header instructions (LANGUAGE OVERRIDE block, appended at runtime
  for English requests) say the same.

Never fill both languages. That wastes ~50 tokens per response.

Return minified JSON only. No fences, no commentary, no token-count claims.
Total output ≤ 1100 tokens.
