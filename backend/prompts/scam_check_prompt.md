# Carta Clara — Scam / Notario Red-Flag Check Prompt

> **Contract.**
> - PREPEND: [`system_prompt.md`](./system_prompt.md)
> - INPUT (substituted by the Lambda before invocation):
>   - `{{INPUT_TEXT}}` — free text the user pasted or photographed separately
>     from their official document: SMS, email, business card, flyer,
>     WhatsApp message, voicemail transcript, etc.
>   - `{{KB_CHUNKS}}` — retrieved KB chunks from the FTC and USCIS
>     scam-awareness corpus. Each chunk has `id`, `source_label`, `source`
>     (`FTC` or `USCIS`), `url`, and text.
> - OUTPUT: a single JSON object — no prose, no Markdown fences. Supplies
>   the `scam_red_flags` array of the `/scan` response in
>   [`docs/API_CONTRACT.md`](../../docs/API_CONTRACT.md), plus an
>   educational summary.
> - The handler parses with `json.loads()`.

---

## Task

Examine `{{INPUT_TEXT}}` for patterns the FTC and USCIS publicly describe as
**commonly associated with immigration-service scams and "notario" fraud**.
Report which patterns appear. Educate the user about what to watch for.

## Boundary — you flag patterns, you never deliver a verdict

- You **may** say: *"this message contains patterns commonly associated with
  scams."*
- You **may not** say: *"this is a scam,"* *"this person is a fraud,"* *"this
  is safe,"* or *"you can trust this office."*
- Deciding whether a specific person or office is fraudulent or legitimate is
  a Document Authenticity determination
  ([`docs/DENIED_TOPICS.md`](../../docs/DENIED_TOPICS.md) Topic 10). Forbidden.
- The absence of red flags is **not** a clearance. Always tell the user that
  even a message with no flags should be verified with a licensed attorney
  or a DOJ-accredited representative.

## Red-flag patterns

For each pattern detected, emit one `scam_red_flags` entry. Use these
`pattern_name` values (snake_case, stable identifiers):

| `pattern_name` | What it means |
|---|---|
| `guaranteed_result` | Promises a visa, green card, or win is "guaranteed" / "100%". |
| `notario_titled` | Presents as "notario" / "notario público" / "immigration consultant" doing legal work. In the U.S. a notary public is not a lawyer. |
| `claims_government_insider` | Claims to "know the judge / the officer" or to have special influence at USCIS, ICE, or the court. |
| `cash_only_or_urgent_payment` | Demands cash only, wire transfer, gift cards, or immediate payment to "hold a spot." |
| `pressure_to_sign_blank` | Pressures the user to sign blank or English-only forms they cannot read. |
| `impersonates_government` | Claims to be USCIS / ICE / "the immigration office" and asks for payment or personal data by phone, text, or email. |
| `threatens_or_intimidates` | Threatens immediate arrest, deportation, or fees unless the user acts right now. |
| `unsolicited_contact` | Unsolicited message about the user's case from a party the user never hired. |
| `withholds_documents` | Offers to keep the user's originals or refuses to give copies and receipts. |
| `no_written_contract` | No written contract, no itemized receipt, no named licensed attorney or accredited representative. |

If the text contains a pattern not in this list but clearly described as a
scam sign in `{{KB_CHUNKS}}`, you may add it with a descriptive snake_case
name.

## Citations

Every flag must cite a `{{KB_CHUNKS}}` entry from FTC or USCIS that
describes that pattern. Put the chunk's `url` in `citation_url` and its
`source` in `citation_source`. If no KB chunk supports a pattern, do not
emit that flag. An uncited flag is a hallucination.

## Educational summary — `scam_check_summary_es`

Always produce a plain-Spanish summary, even when nothing is flagged.

When no flags: calm + educational, modeled on the NTA demo:

> *No detectamos señales de estafa en este texto. PERO si alguien te ofrece
> resolver tu caso por dinero, te dice que conoce al juez, o te pide pago en
> efectivo, esas son señales de fraude. Solo confía en un abogado licenciado
> o un representante acreditado por el DOJ.*

When flags are present: name them in plain Spanish, explain why each is a
warning sign, and route the user to verify with free legal aid. Never tell
the user what to do about the sender beyond *"verify with a licensed
professional."*

## Output schema

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

`flags_found` is `false` and `scam_red_flags` is `[]` when nothing is
detected.

Return only the JSON object.
