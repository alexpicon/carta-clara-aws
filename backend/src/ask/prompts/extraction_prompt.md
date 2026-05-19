# Carta Clara — Document Extraction Prompt

> **Contract.**
> - PREPEND: [`system_prompt.md`](./system_prompt.md)
> - INPUT: a block of plain text OCR-extracted by Amazon Textract (line-by-line).
>   The text may already contain redaction tokens (`[REDACTED_NAME]`,
>   `[REDACTED_A_NUMBER]`, `[REDACTED_ADDRESS]`, `[REDACTED_CASE_NUMBER]`,
>   `[REDACTED_RECEIPT_NUMBER]`).
> - OUTPUT: a single JSON object — no prose, no Markdown fences. Matches the
>   `extraction` object in [`docs/API_CONTRACT.md`](../../docs/API_CONTRACT.md).
> - The handler parses with `json.loads()`. Any non-JSON output is a hard failure.

---

## Task

Extract structured facts from the OCR text into the JSON schema below. Read
only what appears in the text. Do not infer, guess, or fill in fields from
outside knowledge. If OCR clearly garbled a token (random characters, missing
spaces), prefer marking the field uncertain over guessing the intended word.

## Output schema (return exactly these keys)

```json
{
  "document_type": "string — e.g. 'Notice to Appear (Form I-862)'; 'Unknown document' if unclear",
  "issuing_agency": "string — agency named on the document, or 'Unknown'",
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

1. **Redaction flags.** Set `names_redacted` / `a_number_redacted` /
   `address_redacted` to `true` if the corresponding field shows a redaction
   token OR is not present. Set to `false` only if you can see an actual,
   unmasked value of that type.
2. **Dates.** Convert every date to ISO `YYYY-MM-DD`. If a date is partial or
   ambiguous, set the field to `null` and add the field name to
   `fields_uncertain`.
3. **`deadline_critical`.** The most consequential date for the user (a hearing
   date, a response-by date). If none exists, `null`.
4. **`alleged_basis_summary`.** Neutrally restate what the document claims —
   e.g. *"Overstay of B-2 nonimmigrant admission beyond [date]."* Do not
   evaluate whether the claim is true, strong, or weak. That is legal analysis
   and is forbidden.
5. **`issuing_officer`.** Capture the role/title (e.g. *"Deportation Officer,
   U.S. ICE"*). If only a redacted name is visible, return the title alone.
6. **`charges_cited`.** Copy statute references verbatim (e.g. *"INA section
   237(a)(1)(B)"*). Do not interpret here. Interpretation happens in the
   summary step.
7. **`extraction_confidence`.** Use `low` if the image is blurry, cropped, or
   hard to read; list the affected fields in `fields_uncertain`. Never
   substitute a guess for `null`.
8. **No invention.** If a fact is not on the page, the value is `null` or
   `"Unknown"`. Never produce a plausible-sounding placeholder.

## Demo-document classification (telemetry only)

Scan the OCR text for a synthetic-document watermark:

- If the text contains `DEMO – NOT A REAL CASE`, `*** DEMO DOCUMENT ***`, or
  `SYNTHETIC`, set both `is_demo_document` and `demo_watermark_detected` to
  `true`.
- Otherwise, set both to `false`.

These booleans are UI telemetry. They do **not** gate extraction. Process
every document the user submits, real or synthetic — the redaction pipeline
keeps real PII safe regardless of watermark.

Return only the JSON object. No explanation before or after it.
