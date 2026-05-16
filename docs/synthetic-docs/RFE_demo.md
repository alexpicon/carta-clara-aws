# Synthetic Request for Evidence (RFE) — DEMO DOCUMENT

**⚠️ THIS IS A SYNTHETIC DEMO DOCUMENT. ALL NAMES, ADDRESSES, RECEIPT NUMBERS, AND
A-NUMBERS ARE FICTIONAL. NOT BASED ON ANY REAL PERSON OR CASE. FOR HACKATHON
DEMONSTRATION ONLY — `DEMO – NOT A REAL CASE`.**

---

## Purpose — the "judge curveball" backup

`NTA_demo.md` is the primary demo document. This RFE is the **backup** for the moment
a judge says *"try it on a different document."* It is a different document type
(USCIS Form I-797E, Request for Evidence, on a marriage-based I-130 petition) and it
exercises the **same pipeline**: multimodal extraction → Spanish summary → response
preparation packet. No new code path — it proves the architecture generalizes.

Same watermark and synthetic-data rules as `NTA_demo.md` apply (see `TENETS.md` §6).

---

## How to use this document

1. **PDF** — formatted to mimic a real USCIS Form I-797E Notice of Action layout
   (header, receipt block, body, signature block). Watermark `DEMO – NOT A REAL CASE`
   in 60% gray, 45° diagonal. Print on plain paper — this is what gets photographed.
2. **Test image** — a phone-camera photo of the printed PDF, saved as
   `docs/synthetic-docs/RFE_demo.jpg`. This is what the Bedrock multimodal pipeline
   is tested against.

Watermark rules are non-negotiable and identical to `NTA_demo.md`: every printed
copy, every screenshot, every slide/Devpost/video appearance shows the watermark.

---

## Document text (source)

```
                    U.S. DEPARTMENT OF HOMELAND SECURITY
                  U.S. Citizenship and Immigration Services

                            NOTICE OF ACTION
                         REQUEST FOR EVIDENCE
                              Form I-797E

                         *** DEMO DOCUMENT ***
                    *** NOT A REAL CASE — SYNTHETIC ***
                    *** For hackathon use only ***

Receipt Number:  MSC2690154321
Case Type:       I-130, PETITION FOR ALIEN RELATIVE
Received Date:   April 18, 2026
Notice Date:     September 3, 2026

Petitioner:            ROSA M. CASTILLO TORRES
Beneficiary:           DANIEL ANDRES VEGA MORALES
Beneficiary A-Number:  A 088 145 902

    ROSA M. CASTILLO TORRES
    2210 East Marigold Street, Apt. 7
    Tukwila, WA 98168

IMPORTANT: THIS NOTICE IS A REQUEST FOR EVIDENCE. IT IS NOT A DENIAL.

USCIS has reviewed your Form I-130, Petition for Alien Relative, filed on
behalf of your spouse. We need additional evidence before we can continue
processing your petition.

To establish eligibility, you must show that your marriage to the
beneficiary is bona fide -- that is, that you entered the marriage to build
a life together, and not for the purpose of obtaining an immigration
benefit.

The evidence submitted with your petition is insufficient to establish a
bona fide marriage. Please submit additional documentation, which may
include:

  - Documentation showing joint ownership of property, or a shared
    residential lease or mortgage in the names of both spouses.
  - Documentation showing the commingling of finances, such as joint bank
    account statements, joint credit accounts, or jointly filed tax returns.
  - Birth certificates of any children born to you and the beneficiary
    together.
  - Insurance documents (health, life, automobile, or home) listing both
    spouses.
  - Sworn affidavits from at least two people who have personal knowledge
    of the bona fides of your marriage. Each affidavit must state the full
    name, address, and date and place of birth of the person making it, and
    must fully explain how that person acquired their knowledge.
  - Any other probative evidence, such as photographs together over time,
    correspondence, or evidence of joint travel.

YOUR RESPONSE MUST BE RECEIVED BY USCIS ON OR BEFORE NOVEMBER 30, 2026.

Place all requested evidence, along with a copy of this notice, in a single
envelope and mail it to the address shown on this notice. If USCIS does not
receive your response by the date above, we may adjudicate your case based
on the evidence already in the record. This may result in a denial of your
petition.

This notice does not grant any immigration status or benefit, and does not
guarantee any future action by USCIS.

                                       U.S. Citizenship and Immigration
                                       Services
                                       National Benefits Center

                         *** DEMO DOCUMENT ***
                    *** NOT A REAL CASE — SYNTHETIC ***
```

---

## What the Bedrock multimodal extraction should return

Redaction note (same as `NTA_demo.md`): Guardrails masks PII before the model sees the
image. The model never sees "Rosa Castillo Torres", "Daniel Vega Morales",
"A 088 145 902", "MSC2690154321", or the street address — it sees `[REDACTED_NAME]`,
`[REDACTED_A_NUMBER]`, `[REDACTED_RECEIPT_NUMBER]`, `[REDACTED_ADDRESS]`. So the
`_redacted` flags are all `true`.

```json
{
  "document_type": "Request for Evidence (Form I-797E)",
  "issuing_agency": "U.S. Department of Homeland Security — U.S. Citizenship and Immigration Services",
  "names_redacted": true,
  "a_number_redacted": true,
  "address_redacted": true,
  "country_of_origin": null,
  "country_of_citizenship": null,
  "hearing_date": null,
  "hearing_time": null,
  "court_name": null,
  "court_address": null,
  "issuing_officer": "U.S. Citizenship and Immigration Services, National Benefits Center",
  "alleged_basis_summary": "USCIS requests additional evidence that the marriage underlying a Form I-130 petition is bona fide. The notice is a Request for Evidence, not a denial.",
  "charges_cited": [],
  "deadline_critical": "2026-11-30",
  "is_demo_document": true,
  "demo_watermark_detected": true,
  "extraction_confidence": "high",
  "fields_uncertain": []
}
```

Note for the team: an RFE has no hearing — `hearing_date`, `hearing_time`,
`court_name`, `court_address` are correctly `null`, and `charges_cited` is `[]`.
`deadline_critical` is the RFE response-by date. This is exactly why the RFE is a good
curveball: it shows the extraction schema degrades gracefully on a document type with
a very different shape, with no code change.

---

## What the Spanish summary should say

5th-grade-reading-level Spanish (`beginner` slider setting):

> Recibiste una carta de USCIS que se llama "Solicitud de Evidencia". Esto NO es una
> negación. USCIS revisó tu petición de matrimonio y necesita más pruebas de que tu
> matrimonio es de verdad. Te piden cosas como cuentas de banco juntas, un contrato de
> renta con los dos nombres, fotos, y cartas de personas que conocen su matrimonio.
> Tienes que enviar los documentos antes del 30 de noviembre de 2026. Si no respondes
> a tiempo, pueden negar la petición. No estás solo: junta los documentos y habla con
> ayuda legal de inmigración pronto.

Headline summary in Spanish (1–2 sentences, for the audio):

> Es una Solicitud de Evidencia de USCIS sobre tu petición de matrimonio. No es una
> negación — pide más pruebas antes del 30 de noviembre. Junta los documentos y busca
> ayuda legal gratis pronto.

---

## What the scam/notario red-flag check should say for this doc

This RFE is a legitimate-looking official USCIS notice, so the scam check returns the
same kind of educational, no-flags response demonstrated in `NTA_demo.md`:

> No detectamos señales de estafa en este documento. Es una carta oficial de USCIS.
> PERO — si alguien fuera de USCIS te ofrece "garantizar" la aprobación, te pide pago
> en efectivo, o te dice que firmes formularios en blanco, esas son señales de fraude.
> Un "notario público" en Estados Unidos no es abogado. Confía solo en un abogado
> licenciado o un representante acreditado por el DOJ.

---

## What the Response Preparation Packet should contain

When the user taps "Help Me Respond" → "Generate Preparation Packet":

1. **What this document says** (plain Spanish, 1 paragraph) — USCIS asked for more
   evidence that the marriage is real; it is not a denial.
2. **Your deadline** — November 30, 2026 (the date the response must be RECEIVED by
   USCIS, mailed to the address on the notice).
3. **Documents to gather before your legal aid appointment** — joint lease or mortgage,
   joint bank/credit accounts, jointly filed tax returns, children's birth
   certificates, insurance listing both spouses, photographs together over time,
   sworn affidavits from people who know the marriage, joint travel records. (Generic
   evidence categories — the packet lists what the notice asks for; it does not build
   a legal theory of the case.)
4. **A note about the affidavits** — what an affidavit is, and that each must include
   the writer's full name, address, date and place of birth, and how they know the
   marriage is genuine. (Definition only; the lawyer guides the content.)
5. **A phone-call script for legal aid intake** (plain Spanish):
   > Hola, mi nombre es ___. Recibí una Solicitud de Evidencia de USCIS sobre mi
   > petición de matrimonio (Formulario I-130). La respuesta tiene que llegar antes
   > del 30 de noviembre de 2026. Necesito ayuda. ¿Cuándo puedo tener una consulta
   > gratis?
6. **Questions to ask your lawyer**:
   - ¿Qué evidencia es la más importante para mi caso?
   - ¿Cómo deben escribirse las declaraciones juradas (affidavits)?
   - ¿Qué pasa si no tengo algunos de los documentos que piden?
   - ¿Cómo y a dónde se envía la respuesta?
   - ¿Puedo pedir más tiempo si lo necesito?
7. **Cover sheet**:
   > Lleva este paquete a tu cita con ayuda legal gratis. Tu abogado va a preparar la
   > respuesta oficial a USCIS. Este paquete te ayuda a llegar preparado.
8. **Free legal aid options in Seattle** — populated by the backend from
   `kb-corpus/seattle_legal_aid.txt` (NIRP, Colectiva, ReWA, and others).

**Tenet guard (TENETS bright line):** the packet must NOT draft the substantive RFE
response or the cover letter to USCIS. It lists evidence *categories* and questions
for the attorney. The attorney prepares the actual filing.

---

## Why this specific document was chosen for the backup

An RFE is the right curveball because it is genuinely different from an NTA — a
benefit petition rather than a removal case, a mailing deadline rather than a hearing
date, no charges, no court — yet it lands on the same kitchen counter with the same
fear. Demonstrating that one pipeline handles both, with the same extraction schema
and the same trust stack (redaction, grounded summary, refusal of advice, escalation
to free human help), is the Think Big proof: the architecture is the product.

---

## Production note

Same as `NTA_demo.md`: the team must NEVER use a real RFE from a real person, even
redacted, even with permission. Synthetic data only, always. See `TENETS.md` §6.
