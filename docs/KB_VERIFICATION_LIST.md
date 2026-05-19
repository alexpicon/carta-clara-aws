# Carta Clara — Knowledge Base Verification List

**Purpose.** Every substantive factual claim in the `kb-corpus/` files, one per row,
with the live source URL to check it against. The bio teammate works through this
table **Saturday morning**, before the pitch, and marks each row.

**Why this exists.** The KB files were curated on 2026-05-16. The web fetcher in the
build environment was blocked (HTTP 403) by `uscis.gov`, `ftc.gov`, and `justice.gov`,
so content was assembled from those domains' search-indexed excerpts plus stable
public guidance. That is faithful but **not the same as reading the live page**.
TENETS §4 — "citations are the proof" — means a wrong claim in the KB is a trust
failure. This list makes verification a checklist, not a vibe.

**How to use.** For each row: open the Live source URL, find the claim, mark Status:
- ✅ VERIFIED — claim matches the live source.
- ✏️ AMENDED — claim was slightly off; corrected in the KB file (note the change).
- ❌ REMOVED — claim could not be verified; removed from the KB file.

Highest priority: the **legal-aid contact rows** (a wrong phone number sends a scared
user nowhere) and the **statute / form-number rows**.

---

## Priority 1 — Legal-aid contacts (`kb-corpus/seattle_legal_aid.txt`)

These were gathered via web search, NOT confirmed by phone. **Call each org to
confirm**, or verify against the org's own website. Status column starts UNVERIFIED.

| Claim | KB file | KB chunk ID | Live source URL | Status |
|-------|---------|-------------|-----------------|--------|
| NWIRP Seattle phone is 206-587-4009 | seattle_legal_aid.txt | legalaid-01 | https://www.nwirp.org/resources/contact/ | UNVERIFIED |
| NWIRP address is 615 Second Avenue, Suite 400, Seattle, WA 98104 | seattle_legal_aid.txt | legalaid-01 | https://www.nwirp.org/resources/contact/ | UNVERIFIED |
| NWIRP hours M-F 9:00-12:00 & 1:00-4:30 | seattle_legal_aid.txt | legalaid-01 | https://www.nwirp.org/get-help/ | UNVERIFIED |
| Colectiva Legal del Pueblo phone is 206-931-1514 | seattle_legal_aid.txt | legalaid-02 | https://colectivalegal.org/contact-us/ | UNVERIFIED |
| Colectiva address is 13838 First Avenue S, Burien, WA 98168 | seattle_legal_aid.txt | legalaid-02 | https://colectivalegal.org/contact-us/ | UNVERIFIED |
| Colectiva hours Mon/Tue/Thu/Fri 9-5 (closed Wed) | seattle_legal_aid.txt | legalaid-02 | https://colectivalegal.org/contact-us/ | UNVERIFIED |
| ReWA main phone 206-721-0243; helpline 1-888-847-7205 | seattle_legal_aid.txt | legalaid-03 | https://www.rewa.org/contact/ | UNVERIFIED |
| ReWA address 4008 Martin Luther King Jr. Way S, Seattle, WA 98108 | seattle_legal_aid.txt | legalaid-03 | https://www.rewa.org/contact/ | UNVERIFIED |
| IRC SeaTac phone 206-623-2105 | seattle_legal_aid.txt | legalaid-04 | https://www.rescue.org/united-states/seattle-wa | UNVERIFIED |
| IRC SeaTac address 1200 S 192nd St, Suite 101, SeaTac, WA 98148 | seattle_legal_aid.txt | legalaid-04 | https://www.rescue.org/united-states/seattle-wa | UNVERIFIED |
| Lutheran Community Services NW / Safe Route phone 206-694-5742 | seattle_legal_aid.txt | legalaid-05 | https://www.saferoute.org/ | UNVERIFIED |
| Lutheran/Safe Route is a DOJ-recognized program | seattle_legal_aid.txt | legalaid-05 | https://www.saferoute.org/ | UNVERIFIED |
| Catholic Immigration Legal Services intake 206-328-6314 / 206-328-5714 | seattle_legal_aid.txt | legalaid-06 | https://ccsww.org/services/catholic-immigration-legal-services/ | UNVERIFIED |
| CILS address 100 23rd Avenue S, Seattle, WA 98144 | seattle_legal_aid.txt | legalaid-06 | https://ccsww.org/services/catholic-immigration-legal-services/ | UNVERIFIED |
| CILS is a DOJ-recognized organization | seattle_legal_aid.txt | legalaid-06 | https://ccsww.org/services/catholic-immigration-legal-services/ | UNVERIFIED |

---

## Priority 2 — Statute / form-number / process claims (`kb-corpus/eoir_practice_manual_nta.txt`)

| Claim | KB file | KB chunk ID | Live source URL | Status |
|-------|---------|-------------|-----------------|--------|
| A Notice to Appear is Form I-862, the charging document that begins removal proceedings | eoir_practice_manual_nta.txt | eoir-01 | https://www.justice.gov/eoir/reference-materials/ic | UNVERIFIED |
| Removal proceedings are conducted under INA section 240 | eoir_practice_manual_nta.txt | eoir-01 | https://www.justice.gov/eoir/reference-materials/ic | UNVERIFIED |
| Immigration court / EOIR is part of the U.S. Department of Justice; not a criminal court | eoir_practice_manual_nta.txt | eoir-02 | https://www.justice.gov/eoir/about-office | UNVERIFIED |
| INA 237(a)(1)(B) makes an admitted nonimmigrant who overstays removable | eoir_practice_manual_nta.txt | eoir-04 | https://uscode.house.gov/ (8 USC 1227) / https://www.uscis.gov/laws-and-policy | UNVERIFIED |
| The first hearing is usually a "master calendar hearing" (scheduling/preliminary) | eoir_practice_manual_nta.txt | eoir-05 | https://www.justice.gov/eoir/reference-materials/ic | UNVERIFIED |
| Contested cases / relief applications get an "individual (merits) hearing" | eoir_practice_manual_nta.txt | eoir-07 | https://www.justice.gov/eoir/reference-materials/ic | UNVERIFIED |
| Respondent may be represented at no expense to the government | eoir_practice_manual_nta.txt | eoir-08 | https://www.justice.gov/eoir/find-legal-representation | UNVERIFIED |
| Respondent has the right to an interpreter, to examine/present evidence, and to appeal to the BIA | eoir_practice_manual_nta.txt | eoir-08 | https://www.justice.gov/eoir/board-of-immigration-appeals | UNVERIFIED |
| Failure to appear can result in an in-absentia removal order | eoir_practice_manual_nta.txt | eoir-09 | https://www.justice.gov/eoir/reference-materials/ic | UNVERIFIED |
| EOIR maintains a List of Pro Bono Legal Service Providers | eoir_practice_manual_nta.txt | eoir-10 | https://www.justice.gov/eoir/list-pro-bono-legal-service-providers | UNVERIFIED |

---

## Priority 3 — USCIS scam-awareness claims (`kb-corpus/uscis_avoid_scams.txt`)

| Claim | KB file | KB chunk ID | Live source URL | Status |
|-------|---------|-------------|-----------------|--------|
| In the U.S. a notary public ("notario") is not authorized to give immigration legal advice | uscis_avoid_scams.txt | uscis-02 | https://www.uscis.gov/scams-fraud-and-misconduct/avoid-scams/common-scams | UNVERIFIED |
| Only licensed attorneys and DOJ-accredited representatives can give immigration legal advice | uscis_avoid_scams.txt | uscis-03 | https://www.uscis.gov/scams-fraud-and-misconduct/avoid-scams/find-legal-services | UNVERIFIED |
| Accredited representatives may charge only small fees | uscis_avoid_scams.txt | uscis-03 | https://www.justice.gov/eoir/recognition-and-accreditation-program | UNVERIFIED |
| USCIS will never ask for payment over the phone or by email | uscis_avoid_scams.txt | uscis-04 | https://www.uscis.gov/scams-fraud-and-misconduct/avoid-scams/common-scams | UNVERIFIED |
| Suspicious USCIS-impersonation emails can be reported to uscis.webmaster@uscis.dhs.gov | uscis_avoid_scams.txt | uscis-04 | https://www.uscis.gov/report-fraud | UNVERIFIED |
| Official USCIS forms are free to download at uscis.gov/forms | uscis_avoid_scams.txt | uscis-06 | https://www.uscis.gov/forms | UNVERIFIED |
| The U.S. government does not accept gift cards, wire transfers, or cryptocurrency for immigration fees | uscis_avoid_scams.txt | uscis-07 | https://www.uscis.gov/scams-fraud-and-misconduct/avoid-scams/common-scams | UNVERIFIED |
| No one can guarantee USCIS will approve an application | uscis_avoid_scams.txt | uscis-08 | https://www.uscis.gov/scams-fraud-and-misconduct/avoid-scams/common-scams | UNVERIFIED |
| The Diversity Visa lottery is free and run by the U.S. Department of State | uscis_avoid_scams.txt | uscis-08 | https://travel.state.gov/content/travel/en/us-visas/immigrate/diversity-visa-program-entry.html | UNVERIFIED |
| Protect-yourself tips: don't sign blank forms, keep copies, don't surrender originals, get a written contract | uscis_avoid_scams.txt | uscis-09 | https://www.uscis.gov/scams-fraud-and-misconduct/avoid-scams | UNVERIFIED |
| Scams can be reported to the FTC at ReportFraud.ftc.gov or 1-877-FTC-HELP (1-877-382-4357) | uscis_avoid_scams.txt | uscis-10 | https://reportfraud.ftc.gov/ | UNVERIFIED |

---

## Priority 4 — FTC scam-awareness claims (`kb-corpus/ftc_immigration_scams.txt`)

| Claim | KB file | KB chunk ID | Live source URL | Status |
|-------|---------|-------------|-----------------|--------|
| In the U.S., notarios / notary publics are not lawyers and not authorized to provide immigration services | ftc_immigration_scams.txt | ftc-02 | https://consumer.ftc.gov/articles/how-avoid-immigration-scams-get-real-help | UNVERIFIED |
| Only a U.S.-licensed attorney or a DOJ-accredited representative can legally advise/represent on immigration | ftc_immigration_scams.txt | ftc-03 | https://consumer.ftc.gov/articles/how-avoid-immigration-scams-get-real-help | UNVERIFIED |
| No one can guarantee an immigration application will be approved | ftc_immigration_scams.txt | ftc-04 | https://consumer.ftc.gov/articles/how-avoid-immigration-scams-get-real-help | UNVERIFIED |
| Do not sign blank immigration forms or forms with false information | ftc_immigration_scams.txt | ftc-05 | https://consumer.ftc.gov/articles/how-avoid-immigration-scams-get-real-help | UNVERIFIED |
| Official U.S. government immigration forms are free from uscis.gov | ftc_immigration_scams.txt | ftc-06 | https://consumer.ftc.gov/articles/how-avoid-immigration-scams-get-real-help | UNVERIFIED |
| A demand to pay by gift card, wire transfer, payment app, or crypto is a scam | ftc_immigration_scams.txt | ftc-07 | https://consumer.ftc.gov/articles/how-to-avoid-a-scam | UNVERIFIED |
| Real U.S. government websites end in ".gov" | ftc_immigration_scams.txt | ftc-08 | https://consumer.ftc.gov/articles/how-avoid-immigration-scams-get-real-help | UNVERIFIED |
| Immigration scams can be reported to the FTC at ReportFraud.ftc.gov | ftc_immigration_scams.txt | ftc-10 | https://reportfraud.ftc.gov/ | UNVERIFIED |

---

## Priority 5 — Glossary factual claims (`kb-corpus/immigration_terms_glossary_es.txt`)

Most glossary rows are plain-language definitions. The rows below carry a *factual*
assertion beyond a definition and should be spot-checked; the rest can be checked
against the USCIS glossary as a batch.

| Claim | KB file | KB chunk ID / term | Live source URL | Status |
|-------|---------|--------------------|-----------------|--------|
| "Notice to Appear" = the document that begins an immigration court case | immigration_terms_glossary_es.txt | term: Notice to Appear | https://www.uscis.gov/tools/glossary | UNVERIFIED |
| In the U.S. a "notario público" is not a lawyer and cannot give immigration legal advice | immigration_terms_glossary_es.txt | term: Notario público | https://www.uscis.gov/scams-fraud-and-misconduct/avoid-scams/common-scams | UNVERIFIED |
| The INA is the principal U.S. federal immigration law | immigration_terms_glossary_es.txt | term: INA | https://www.uscis.gov/laws-and-policy/legislation/immigration-and-nationality-act | UNVERIFIED |
| A person in immigration court has the right to an interpreter | immigration_terms_glossary_es.txt | term: Interpreter | https://www.justice.gov/eoir | UNVERIFIED |
| The BIA reviews appeals of immigration judges' decisions | immigration_terms_glossary_es.txt | term: BIA | https://www.justice.gov/eoir/board-of-immigration-appeals | UNVERIFIED |
| An accredited representative is DOJ-authorized non-attorney who may represent clients | immigration_terms_glossary_es.txt | term: Accredited representative | https://www.justice.gov/eoir/recognition-and-accreditation-program | UNVERIFIED |
| Remaining glossary entries (general definitions) | immigration_terms_glossary_es.txt | all other terms | https://www.uscis.gov/tools/glossary | UNVERIFIED (batch check) |

---

## Verification summary (fill in Saturday morning)

| Priority | Rows | ✅ Verified | ✏️ Amended | ❌ Removed |
|----------|------|------------|-----------|-----------|
| P1 Legal-aid contacts | 15 | | | |
| P2 Statute / process | 10 | | | |
| P3 USCIS scams | 11 | | | |
| P4 FTC scams | 8 | | | |
| P5 Glossary | 7 | | | |
| **Total** | **51** | | | |

If any row is ❌ REMOVED, also remove or fix any prompt/eval reference that depended
on it (check `docs/EVAL_PROMPTS_EXPECTED.md` citation columns). If a legal-aid contact
changes, update `kb-corpus/seattle_legal_aid.txt` AND the iOS `LegalHelpView`,
which hard-codes NIRP / Colectiva / ReWA contacts from that file.
