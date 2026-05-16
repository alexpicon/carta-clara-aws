# Carta Clara — Document Extraction Prompt (multimodal)

> Contract
> - PREPEND: backend/prompts/system_prompt.md
> - INPUT: one document image (JPEG/PNG) passed as a multimodal content block.
>   The image has already passed through Guardrails PII masking — visible PII
>   appears as redaction tokens (`[REDACTED_NAME]`, `[REDACTED_A_NUMBER]`,
>   `[REDACTED_ADDRESS]`, `[REDACTED_CASE_NUMBER]`, `[REDACTED_RECEIPT_NUMBER]`).
> - OUTPUT: a single JSON object, no prose, no markdown fences. Matches the
>   `extraction` object in docs/API_CONTRACT.md (POST /scan response).
> - Koda parses this with `json.loads()`. Any non-JSON output is a hard failure.

---

## Task

You are reading a photograph of an English-language government or civic document.
Extract structured facts into the JSON schema below. Read only what is on the page.
Do not infer, guess, or fill in fields from outside knowledge.

## Output schema (return EXACTLY these keys)

```json
{
  "document_type": "string — e.g. 'Notice to Appear (Form I-862)'; 'Unknown document' if unclear",
  "issuing_agency": "string — the agency named on the document, or 'Unknown'",
  "names_redacted": true,
  "a_number_redacted": true,
  "address_redacted": true,
  "country_of_origin": "string or null",
  "country_of_citizenship": "string or null",
  "hearing_date": "ISO date YYYY-MM-DD or null",
  "hearing_time": "HH:MM 24-hour or null",
  "court_name": "string or null",
  "court_address": "string or null",
  "issuing_officer": "string (role/title only, never a redacted personal name) or null",
  "alleged_basis_summary": "string — neutral paraphrase of what the document alleges, or null",
  "charges_cited": ["string — statute/section references exactly as printed"],
  "deadline_critical": "ISO date YYYY-MM-DD — the single most time-sensitive date, or null",
  "is_demo_document": true,
  "demo_watermark_detected": true,
  "extraction_confidence": "high | medium | low",
  "fields_uncertain": ["string — names of any fields you were unsure about"]
}
```

## Extraction rules

1. **Redaction flags.** Set `names_redacted` / `a_number_redacted` / `address_redacted`
   to `true` if the corresponding field on the page shows a redaction token OR is not
   present. Set to `false` only if you can see an actual, unmasked value of that type.
2. **Dates.** Convert every date to ISO `YYYY-MM-DD`. If a date is partial or
   ambiguous, set the field to `null` and add the field name to `fields_uncertain`.
3. **`deadline_critical`.** The most consequential date for the user (a hearing date,
   a response-by date). If none exists, `null`.
4. **`alleged_basis_summary`.** Neutrally restate what the document claims — e.g.
   "Overstay of B-2 nonimmigrant admission beyond [date]." Do NOT evaluate whether the
   claim is true, strong, or weak. That is legal analysis and is forbidden.
5. **`issuing_officer`.** Capture the role/title (e.g. "Deportation Officer, U.S. ICE").
   If only a redacted name is visible, return the title alone.
6. **`charges_cited`.** Copy statute references verbatim (e.g. "INA section 237(a)(1)(B)").
   Do not interpret them here — interpretation happens in the summary step.
7. **Confidence.** Use `low` if the image is blurry, cropped, or hard to read; list the
   affected fields in `fields_uncertain`. Never substitute a guess for `null`.
8. **No invention.** If a fact is not on the page, the value is `null` or `"Unknown"`.
   Never produce a plausible-sounding placeholder.

## Synthetic-data safety gate (MANDATORY)

This product is tested only on synthetic documents. Before extracting, check the page:

- If you see the watermark `DEMO – NOT A REAL CASE` (or `*** DEMO DOCUMENT ***` /
  `SYNTHETIC`), set `is_demo_document` and `demo_watermark_detected` to `true` and
  proceed normally.
- If the document shows **real, unmasked PII** — a real full name, A-number, SSN, date
  of birth, or address that is NOT behind a redaction token — and there is **no demo
  watermark**, do NOT extract. Instead return this object exactly:

```json
{
  "document_type": "Unknown document",
  "issuing_agency": "Unknown",
  "names_redacted": false,
  "a_number_redacted": false,
  "address_redacted": false,
  "country_of_origin": null,
  "country_of_citizenship": null,
  "hearing_date": null,
  "hearing_time": null,
  "court_name": null,
  "court_address": null,
  "issuing_officer": null,
  "alleged_basis_summary": null,
  "charges_cited": [],
  "deadline_critical": null,
  "is_demo_document": false,
  "demo_watermark_detected": false,
  "extraction_confidence": "low",
  "fields_uncertain": ["refused_real_pii"]
}
```

Koda's handler treats `fields_uncertain == ["refused_real_pii"]` as a refusal:
nothing is stored, and the user is routed to in-person help.

Return only the JSON object. No explanation before or after it.
