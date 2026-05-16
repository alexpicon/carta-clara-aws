# Synthetic Notario Scam SMS — DEMO PROP

**⚠️ THIS IS A SYNTHETIC DEMO MESSAGE. THE SENDER, NAMES, PHONE NUMBERS, AND
"BUSINESS" ARE ALL FICTIONAL. IT IS NOT A REAL TEXT FROM A REAL PERSON OR COMPANY.
IT WAS WRITTEN BY THE CARTA CLARA TEAM TO DEMONSTRATE THE SCAM-CHECK FEATURE. FOR
HACKATHON DEMONSTRATION ONLY — `DEMO – NOT A REAL CASE`.**

---

## Purpose

This is the demo prop for the **scam / notario red-flag check** moment. In the demo,
the user pastes (or photographs) this text into Carta Clara's scam-check input. The
scam-check pipeline runs `backend/prompts/scam_check_prompt.md` and **deterministically
surfaces multiple red flags**, each cited to a KB chunk.

Pairs with: the NTA demo (`docs/synthetic-docs/NTA_demo.md`). Story beat: *"Grandma
got her court notice — and then this text arrived from someone who saw an opportunity."*

---

## SMS source text (this is what gets pasted / photographed)

```
URGENTE — Sra., le escribimos porque vimos que usted tiene un caso
abierto en la corte de inmigración.

El NOTARIO PÚBLICO Juan R. puede resolver su caso rápido. Le
GARANTIZAMOS su permiso de quedarse 100% — o le devolvemos su dinero.

Yo conozco personalmente al juez de la corte de Seattle y tengo
contactos adentro que pueden ayudar con su caso.

Solo aceptamos EFECTIVO: $750 hoy mismo para apartar su cita. Si no
paga HOY, la pueden deportar muy pronto.

No necesita un abogado caro ni contrato. Usted solo firma los
formularios y nosotros los llenamos por usted. Tráiganos su pasaporte
original para guardarlo en su expediente.

Responda YA a este mensaje. — Inmigración Express Services

                  *** DEMO – NOT A REAL CASE ***
              *** Mensaje sintético para demostración ***
```

---

## Formatting spec — how to render this prop

Two output formats, same rules as `NTA_demo.md`:

1. **Screenshot prop (primary).** Render the SMS text above as a phone text-message
   conversation — a single inbound (gray/left-aligned) message bubble from an unknown
   number. Suggested mock sender: `+1 (206) 555-0148` (555-01xx is the fiction-safe
   reserved range). Capture as a clean iPhone Messages-style screenshot.
   - Add the watermark `DEMO – NOT A REAL CASE` in 60% gray, 45° diagonal, across
     the screenshot — same watermark spec as the NTA prop.
   - Save as `docs/synthetic-docs/notario_SMS_demo.png`.
2. **Plain-text fallback.** The fenced block above is the canonical text. If the demo
   pastes text instead of photographing, paste exactly the lines between the fences
   (the `*** DEMO ***` lines may be omitted when pasting, since the screenshot carries
   the watermark — but never omit them from a screenshot).

**Watermark rules (non-negotiable, inherited from `TENETS.md` §6 and `NTA_demo.md`):**
- Every rendered screenshot carries the diagonal `DEMO – NOT A REAL CASE` watermark.
- Every appearance on a slide / Devpost / video shows the watermark.
- The sender number must stay inside the `555-01xx` reserved-fiction range.
- Never use a real notario, real business name, or a real person's text. The business
  name `Inmigración Express Services` and `Notario Público Juan R.` are invented; if
  either turns out to match a real entity, change it.

---

## Expected scam-check output (the demo must surface these)

When `scam_check_prompt.md` processes the SMS text, it should return **9 of the 10
red-flag patterns**. This is the deterministic target — Sunday's eval and the live
demo both check against this list. (Requirement was "at least 5 of 10"; this prop
hits 9 so the demo cannot fall flat.)

| # | `pattern_name` | Triggering text in the SMS | Citation chunk(s) | Source |
|---|----------------|----------------------------|-------------------|--------|
| 1 | `unsolicited_contact` | "le escribimos porque vimos que usted tiene un caso abierto" — unsolicited message about a case the user never hired anyone for | `ftc-08`, `uscis-04` | FTC / USCIS |
| 2 | `notario_titled` | "El NOTARIO PÚBLICO Juan R. puede resolver su caso" | `ftc-02`, `uscis-02` | FTC / USCIS |
| 3 | `guaranteed_result` | "Le GARANTIZAMOS su permiso de quedarse 100%" | `ftc-04`, `uscis-08` | FTC / USCIS |
| 4 | `claims_government_insider` | "conozco personalmente al juez de la corte de Seattle y tengo contactos adentro" | `ftc-04` | FTC |
| 5 | `cash_only_or_urgent_payment` | "Solo aceptamos EFECTIVO: $750 hoy mismo" | `ftc-07`, `uscis-07` | FTC / USCIS |
| 6 | `threatens_or_intimidates` | "Si no paga HOY, la pueden deportar muy pronto" | `ftc-08` | FTC |
| 7 | `no_written_contract` | "No necesita un abogado caro ni contrato" | `ftc-09`, `uscis-09` | FTC / USCIS |
| 8 | `pressure_to_sign_blank` | "Usted solo firma los formularios y nosotros los llenamos por usted" | `ftc-05`, `uscis-09` | FTC / USCIS |
| 9 | `withholds_documents` | "Tráiganos su pasaporte original para guardarlo" | `ftc-09`, `uscis-09` | FTC / USCIS |

Pattern 10, `impersonates_government`, is intentionally NOT triggered — the SMS does
not claim to be USCIS/ICE/the court itself, only to "know" the judge. Leaving one
pattern un-triggered is honest: it shows the check reports what is actually present,
not a fixed list.

**Expected `scam_check_summary_es`** (plain Spanish, calm + educational — the team can
use this as the quality target; the live model output may vary in wording):

> Este mensaje tiene varias señales que comúnmente se asocian con estafas de
> inmigración. Promete un resultado "garantizado", dice que conoce al juez, pide pago
> en efectivo de inmediato, te apura con miedo a la deportación, y quiere guardar tu
> pasaporte original. En Estados Unidos un "notario público" NO es abogado y no puede
> dar consejo legal de inmigración. No detectamos aquí una confirmación de que sea una
> estafa con certeza — pero estas son señales de alerta. Antes de pagar o firmar nada,
> habla con un abogado licenciado o un representante acreditado por el DOJ. Hay ayuda
> legal gratis cerca de ti.

**Boundary reminder (TENETS §3, DENIED_TOPICS Topic 10):** the output flags *patterns*
and educates — it must NOT declare "this is a scam" or "this person is a fraud" with
certainty. "Señales comúnmente asociadas con estafas," never a verdict.

---

## Why this prop was chosen

The notario scam is the single most documented fraud against Spanish-speaking
immigrant families. Showing Carta Clara catch a notario text — right after it calmly
explained a terrifying court notice — proves the product protects the user on *both*
sides: it explains the real document, and it flags the predator who shows up next.
Nine cited red flags in three seconds is a strong, deterministic demo beat.
