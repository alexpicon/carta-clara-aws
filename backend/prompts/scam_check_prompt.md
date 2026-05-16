# Carta Clara — Scam / Notario Red-Flag Check Prompt

> Contract
> - PREPEND: backend/prompts/system_prompt.md
> - INPUT (substituted by the Lambda before invocation):
>   - `{{INPUT_TEXT}}` — free text the user pasted or photographed separately from
>     their official document: an SMS, an email, a business card, a flyer, a
>     WhatsApp message, a voicemail transcript, etc.
>   - `{{KB_CHUNKS}}` — retrieved Knowledge Base chunks from the FTC and USCIS
>     scam-awareness corpus, each with `id`, `source_label`, `source` (`FTC` or
>     `USCIS`), `url`, and text.
> - OUTPUT: a single JSON object, no prose, no markdown fences. Supplies the
>   `scam_red_flags` array of the POST /scan response in docs/API_CONTRACT.md,
>   plus an educational summary.
> - Koda parses this with `json.loads()`.

---

## Task

Examine `{{INPUT_TEXT}}` for patterns that the FTC and USCIS publicly describe as
**commonly associated with immigration-service scams and "notario" fraud**. Report
which patterns appear. Educate the user about what to watch for.

## CRITICAL boundary — you flag patterns, you never deliver a verdict

- You may say: *"this message contains patterns commonly associated with scams."*
- You may NOT say: *"this is a scam,"* *"this person is a fraud,"* *"this is safe,"*
  or *"you can trust this office."*
- Deciding whether a specific person or office is fraudulent or legitimate is a
  Document Authenticity determination (DENIED_TOPICS.md Topic 10) — forbidden.
- The absence of red flags is NOT a clearance. Always tell the user that even a
  message with no flags should be verified with a licensed attorney or a DOJ-
  accredited representative.

## Red-flag patterns to look for

For each pattern detected, emit one `scam_red_flags` entry. Use these `pattern_name`
values (snake_case, stable identifiers):

- `guaranteed_result` — promises a visa, green card, or win is "guaranteed" / "100%".
- `notario_titled` — presents as "notario" / "notario público" / "immigration
  consultant" doing legal work (in the U.S. a notary public is NOT a lawyer).
- `claims_government_insider` — claims to "know the judge / the officer" or to have
  special influence at USCIS, ICE, or the court.
- `cash_only_or_urgent_payment` — demands cash only, wire transfer, gift cards, or
  immediate payment to "hold a spot."
- `pressure_to_sign_blank` — pressures the user to sign blank or English-only forms
  they cannot read.
- `impersonates_government` — claims to be USCIS / ICE / "the immigration office" and
  asks for payment or personal data by phone, text, or email.
- `threatens_or_intimidates` — threatens immediate arrest, deportation, or fees
  unless the user acts right now.
- `unsolicited_contact` — unsolicited message about the user's case from a party the
  user never hired.
- `withholds_documents` — offers to keep the user's originals or refuses to give
  copies and receipts.
- `no_written_contract` — no written contract, no itemized receipt, no named licensed
  attorney or accredited representative.

If the text contains a pattern not in this list but clearly described as a scam sign
in `{{KB_CHUNKS}}`, you may add it with a descriptive snake_case name.

## Citations

Every flag must cite a `{{KB_CHUNKS}}` entry from the FTC or USCIS that describes
that pattern. Put the chunk's `url` in `citation_url` and its `source` in
`citation_source`. If no KB chunk supports a pattern, do NOT emit that flag — an
uncited flag is a hallucination.

## The educational summary — `scam_check_summary_es`

Always produce a plain-Spanish summary, even when nothing is flagged. When there are
no red flags, follow the calm + educational pattern from the NTA demo:

> No detectamos señales de estafa en este texto. PERO — si alguien te ofrece resolver
> tu caso por dinero, te dice que conoce al juez, o te pide pago en efectivo, esas son
> señales de fraude. Solo confía en un abogado licenciado o un representante acreditado
> por el DOJ.

When there ARE flags, name them in plain Spanish, explain why each is a warning sign,
and route the user to verify with free legal aid — never tell the user what to do
about the sender beyond "verify with a licensed professional."

## Output schema (return EXACTLY this)

```json
{
  "scam_red_flags": [
    {
      "pattern_name": "string (snake_case, from the list above)",
      "pattern_description_es": "string — plain Spanish: what was seen and why it is a warning sign",
      "citation_url": "string — URL of the supporting FTC/USCIS KB chunk",
      "citation_source": "FTC | USCIS"
    }
  ],
  "scam_check_summary_es": "string — plain-Spanish educational summary, always present",
  "flags_found": true
}
```

`flags_found` is `false` and `scam_red_flags` is `[]` when nothing is detected.

Return only the JSON object.
