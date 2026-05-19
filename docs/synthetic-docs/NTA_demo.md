# Synthetic Notice to Appear — DEMO DOCUMENT

**⚠️ THIS IS A SYNTHETIC DEMO DOCUMENT. ALL NAMES, ADDRESSES, AND CASE NUMBERS ARE FICTIONAL. NOT BASED ON ANY REAL PERSON OR CASE. FOR HACKATHON DEMONSTRATION ONLY.**

---

## How to use this document

This markdown file is the **source text** for the synthetic demo Notice to Appear. The bio major / PM teammate renders it as a formatted PDF or print-out that looks like a real EOIR Form I-862, then we photograph that print-out on stage.

**Two output formats to produce:**

1. **PDF** — formatted to mimic the real Form I-862 layout (header, sections, signature block). Print on plain paper. Add a watermark `DEMO – NOT A REAL CASE` in 60% gray, 45° diagonal across the page. This is what we photograph.
2. **Test image** — a phone-camera photo of the printed PDF, saved as `docs/synthetic-docs/NTA_demo.jpg`. This is what we test the Bedrock multimodal pipeline against.

**Watermark rules (non-negotiable):**
- Every printed copy has the watermark
- Every screenshot of the document on a Devpost / pitch slide / YouTube video has the watermark visible
- The first 5 seconds of the demo video shows the watermark clearly so anyone watching knows it's synthetic

---

## Document text (source)

```
                    U.S. DEPARTMENT OF JUSTICE
              Executive Office for Immigration Review
                   IMMIGRATION COURT — SEATTLE

                       NOTICE TO APPEAR

                       *** DEMO DOCUMENT ***
                  *** NOT A REAL CASE — SYNTHETIC ***
                  *** For hackathon use only ***

File No.: A 999 999 901
Date: August 12, 2026

In the Matter of:
    MARIA ELENA HERNANDEZ RIVERA                          Respondent
    1428 South Fairmont Avenue, Apt. 3B
    Seattle, WA 98144

In removal proceedings under section 240 of the Immigration and
Nationality Act:

You are an arriving alien.
You are an alien present in the United States who has not been
   admitted or paroled.
[X] You have been admitted to the United States, but are removable for
    the reasons stated below.

The Department of Homeland Security alleges that you:

  1. You are not a citizen or national of the United States.
  2. You are a native of MEXICO and a citizen of MEXICO.
  3. You were admitted to the United States at SAN YSIDRO, CALIFORNIA,
     on or about July 14, 2018, as a non-immigrant B-2 visitor with
     authorization to remain in the United States for a temporary
     period not to exceed January 13, 2019.
  4. You remained in the United States beyond January 13, 2019, without
     authorization from the United States government.

On the basis of the foregoing, it is charged that you are subject to
removal from the United States pursuant to the following provision(s)
of law:

  Section 237(a)(1)(B) of the Immigration and Nationality Act, as
  amended, in that after admission as a nonimmigrant under Section
  101(a)(15) of the Act, you have remained in the United States for a
  time longer than permitted, in violation of this Act or any other
  law of the United States.

YOU ARE ORDERED to appear before an immigration judge of the United
States Department of Justice at:

  SEATTLE IMMIGRATION COURT
  1000 Second Avenue, Suite 2900
  Seattle, WA 98104

  Date of hearing:  OCTOBER 15, 2026
  Time of hearing:  9:00 A.M.

to show why you should not be removed from the United States based on
the charge(s) set forth above.

                                       ___________________________
                                       Officer J. Sample
                                       Deportation Officer
                                       U.S. Immigration and Customs
                                       Enforcement
                                       Date: August 12, 2026

                       *** DEMO DOCUMENT ***
                  *** NOT A REAL CASE — SYNTHETIC ***
```

---

## What the Bedrock multimodal extraction should return

When the system processes a photograph of the above document, the extraction Lambda should return JSON shaped roughly like this:

```json
{
  "document_type": "Notice to Appear (Form I-862)",
  "issuing_agency": "U.S. Department of Justice — Executive Office for Immigration Review",
  "names_redacted": true,
  "a_number_redacted": true,
  "address_redacted": true,
  "country_of_origin": "Mexico",
  "country_of_citizenship": "Mexico",
  "hearing_date": "2026-10-15",
  "hearing_time": "09:00",
  "court_name": "Seattle Immigration Court",
  "court_address": "1000 Second Avenue, Suite 2900, Seattle, WA 98104",
  "issuing_officer": "Officer J. Sample, Deportation Officer, U.S. ICE",
  "alleged_basis_summary": "Overstay of B-2 nonimmigrant admission beyond January 13, 2019",
  "charges_cited": ["INA section 237(a)(1)(B)"],
  "deadline_critical": "2026-10-15",
  "is_demo_document": true,
  "demo_watermark_detected": true
}
```

**Note:** Field names follow `docs/API_CONTRACT.md` exactly — API_CONTRACT is the source of truth on field naming where this doc and the contract differ.

Note: `respondent_name_redacted`, `a_number_redacted`, `address_redacted` are TRUE in the response because Guardrails PII filter masks these *before* the model sees them. The model never sees "Maria Hernandez Rivera" or "A 999 999 901" — it sees `[REDACTED_NAME]`, `[REDACTED_A_NUMBER]`, etc.

---

## What the Spanish summary should say

The model output, in 5th-grade-reading-level Spanish, should be something like:

> Recibiste un aviso del gobierno. El gobierno dice que te quedaste en los Estados Unidos más tiempo del permitido. Tienes que ir a la corte el 15 de octubre de 2026 a las 9 de la mañana. La corte está en Seattle. Esto es serio. No es una decisión final. Tienes derecho a tener un abogado. Puedes pedir ayuda legal gratis. No respondas tú mismo. Habla con un abogado de inmigración pronto.

Headline summary in Spanish (1-2 sentences for the audio):

> Es un aviso para presentarte en la corte de inmigración el 15 de octubre. No es una orden final. Pide ayuda legal gratis lo antes posible.

---

## What the scam/notario red-flag check should say for this doc

For this specific document (which is a legitimate-looking NTA), the scam check should return:

> No detectamos señales de estafa en este documento. Es un aviso oficial del Departamento de Justicia. PERO — si alguien fuera de la corte te ofrece resolver este caso por dinero, te dice que conoce al juez, o te pide pago en efectivo, esas son señales de fraude. Solo confía en un abogado licenciado o un representante acreditado por el DOJ.

This response demonstrates the feature even when there are no red flags in the document itself — the user is educated about what to watch for.

---

## What the Response Preparation Packet should contain

When the user taps "Help Me Respond" → "Generate Preparation Packet," the printable output should include:

1. **What this document says** (plain Spanish, 1 paragraph)
2. **Your hearing date** (October 15, 2026, 9:00 AM, Seattle Immigration Court, 1000 Second Avenue, Suite 2900, Seattle WA 98104)
3. **Documents to gather before your legal aid appointment** (passport / consular ID, any prior immigration paperwork, proof of any time spent in the U.S., proof of family ties in the U.S., any medical records that might be relevant, character references)
4. **A pre-filled request to reschedule (procedural)** — IF the user has a documented conflict with the hearing date, a template form they can fill in
5. **A phone-call script for legal aid intake**:

   > Hola, mi nombre es ___. Recibí un Notice to Appear con fecha de corte el 15 de octubre de 2026 a las 9 de la mañana en la corte de Seattle. Necesito ayuda. ¿Cuándo puedo tener una consulta gratis?

6. **Questions to ask your lawyer**:
   - ¿Qué significa esta acusación en mi caso?
   - ¿Qué tipos de evidencia debería juntar antes de la próxima cita?
   - ¿Necesito hacer algo antes del 15 de octubre?
   - ¿Hay formas de pedir más tiempo si las necesito?
   - ¿Qué pasa si no entiendo algo en la corte?

7. **Cover sheet**:
   > Lleva este paquete a tu cita con ayuda legal gratis. Tu abogado va a escribir la respuesta oficial. Este paquete te ayuda a llegar preparado.

8. **Free legal aid options in Seattle** (with real phone numbers — to be filled in by the bio major from the outreach corpus):
   - Northwest Immigrant Rights Project (NIRP)
   - Colectiva Legal del Pueblo
   - Refugee Women's Alliance (ReWA)

---

## Why this specific document was chosen for the demo

A Notice to Appear is the most emotionally resonant immigration document a family can receive — it's the one that initiates removal proceedings. By demonstrating that Carta Clara can:

1. **Extract** the right structured information from a frightening document
2. **Translate** the meaning (not just the words) into plain Spanish
3. **Refuse** to give legal advice when asked "should I skip this?"
4. **Route** to free legal aid with real phone numbers
5. **Prepare** a packet the user brings to a real lawyer

…the demo shows the entire product in 3 minutes, against the highest-stakes document type the product handles.

---

## Backup document for the "judge curveball" moment

If a judge says "try it on a different document," have ready: **a synthetic Request for Evidence (RFE) — Form I-797E** that asks the user to provide additional evidence of a marriage being bona fide. This shows the product handles a different, complex document type. Bio major to draft using the same conventions as this NTA. Same watermark rules apply.

---

## Production note

**The team must NEVER use a real NTA from a real person**, even with permission, even with names redacted. The risk-to-reward ratio is wrong. Synthetic data only, always. See `docs/TENETS.md` for the bright line.
