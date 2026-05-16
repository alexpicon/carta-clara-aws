# Carta Clara — MVP Definition

This is the single source of truth for **what ships** as Carta Clara MVP. When you're tempted to add a feature, check the "Out of scope" list. When you're tempted to drop one, check "In scope (must-have)." When you need to know whether something is "done," check the "Acceptance criteria."

Everything here is consolidated from `PRESS_RELEASE.md`, `PHASE_PLAN.md`, `TENETS.md`, and `EVAL_PROMPTS_EXPECTED.md`. If this file conflicts with any of those, those win — open a PR to fix this file.

---

## One-line definition

**Carta Clara MVP** is a native iPhone app that photographs an English immigration document and returns, within 30 seconds, a plain summary, a deadline, a scam check, and a printable Response Preparation Packet for free legal aid — refusing every legal-strategy question and routing to a real lawyer instead.

> **Language status (team-development phase, 2026-05-16 →):** the iOS app currently runs **English-default** for team review and operation (TENETS §9, temporarily amended). The backend still produces Spanish content and Polly Lupe audio; the app reads `summary_en` while in this phase. The production target remains **Spanish-first**, and the app will flip back before the pitch. Acceptance criteria below mention Spanish where the backend still owns the content (audio, evaluator-graded grounded prompts).

---

## In scope (must-have for the demo)

These are the features that ship, in priority order. The "Cut order" section below states what gets dropped first if we run out of time — these do **not** get dropped:

1. **Visible PII redaction** — A-number, name, address, DOB, case number are masked on screen *before* anything is sent to a model. The redaction is animated and pedagogical, not silent.
2. **Plain-language summary** — 5th-grade-reading-level text of what the document says. **Currently English** (read from `summary_en` while in dev-mode default). Production target flips back to Spanish (`summary_es`). Polly Spanish audio remains attached either way; audio is preferred but cuttable (see Cut order).
3. **Deadline / urgency card** — the next date the user must act, in Spanish, with a verification line ("Verify this date against the document — Carta Clara can misread handwritten dates").
4. **Scam / notario red-flag card** — pattern-matches against the FTC + USCIS published warning signs. Conditional (only renders when patterns match). Cites the source.
5. **Court Brief card** — for NTAs only. Court name, address, what to expect, what to bring, what to wear. **Never** analyzes the judge.
6. **"Questions for legal aid" card** — a pre-written list of the right questions to ask, scoped to the specific document type.
7. **Response Preparation Packet** — printable, multi-section: translated summary, evidence checklist, pre-filled extension request, legal-aid phone-call script, cover sheet that says "Bring this to your appointment. Your lawyer will write the official response."
8. **Refusal of legal-strategy questions** — every "should I…" question about strategy, eligibility, outcome, hearing attendance, ICE encounters, judge bias, or document authenticity is refused. The refusal is **visible** (counter in the corner, tappable to view log).
9. **Legal-aid escalation** — every refusal routes to at least one of NIRP / Colectiva / ReWA with a real phone number, address, and hours.
10. **Synthetic-only demo doc** — every screenshot, every video frame, every live demo uses a watermarked `DEMO – NOT A REAL CASE` document. Never a real one.

---

## Out of scope (explicit non-goals)

These are deliberate cuts. Each one is a "Think Big" talking point — we considered it, we have a reason, and we will articulate the reason on stage:

- **Languages other than English (dev-mode default) and Spanish (production target).** Korean, Hindi, Mandarin, Tagalog are roadmap. We refuse to ship a language we can't validate against a native speaker on the team. (TENETS §9)
- **User accounts, login, signup, email field.** Ephemeral session only. No password reset flow, ever. (TENETS §7)
- **Persistent document storage.** S3 has a 1-hour TTL. We do not keep the user's documents. (TENETS §7)
- **Legal advice in any form.** No "you should…" answers. No form-selection. No admit/deny guidance. No eligibility opinions. No outcome predictions. (TENETS §3, bright lines)
- **Drafting substantive responses** to USCIS / EOIR / ICE / DHS / a court. The Response Preparation Packet *helps the user talk to a lawyer*; it does not replace the lawyer's response. (Bright line)
- **Judge analytics** or past-case matching of any kind. (Bright line)
- **Real immigration documents** in the product, the demo, the screenshots, the Devpost page, or anywhere else. Permanent — not a hackathon constraint. (TENETS §6)
- **Android, web, or watch versions.** iPhone-only for MVP.
- **Offline mode.** The product requires network to call Bedrock. We will not fake an offline experience.
- **Document types beyond immigration** — utility notices, school letters, IRS mail, lease violations. All roadmap. The architecture is reusable; the MVP is immigration-only.

---

## Acceptance criteria ("done means…")

A feature is **done** when its row here is true. Not when the code compiles. Not when the screen renders. When the row is true.

| Feature | Done means… |
|---------|-------------|
| PII redaction | A live demo on a physical iPhone shows the A-number visibly being masked on screen before the network request fires. Verified in Network Inspector that the outbound payload contains the redacted form. |
| Plain summary (text) | A synthetic NTA scan returns a headline summary that a team reviewer confirms is (a) correct, (b) at 5th-grade reading level, (c) uses no untranslated legal jargon. **Currently graded in English**; before pitch, re-grade in Spanish against a native speaker. |
| Spanish summary (audio) | Tapping the audio button plays back the Spanish text via Polly voice `Lupe`, within 3 seconds of tap, audible without headphones in a quiet room. (Audio remains Spanish even while UI is English — it's the bilingual helper handle.) |
| Deadline card | The deadline card renders the exact date from the synthetic NTA (2026-10-15) with the verification line in Spanish. |
| Scam red-flag card | Running the synthetic notario SMS through the app surfaces at least 3 FTC/USCIS-defined red flags, each with a citation chip linking back to a `kb-corpus/` source. |
| Court Brief card | Running the synthetic NTA surfaces a Court Brief naming "Seattle Immigration Court, 1000 Second Avenue, Suite 2900, Seattle, WA 98104" with a what-to-expect paragraph and zero analysis of any judge. |
| Questions for legal aid | At least 5 document-scoped questions render, each in Spanish, each a question a lawyer would actually need answered (not generic). |
| Response Preparation Packet | The packet renders as a multi-section, printable view that fits on standard letter paper. A team member prints one and confirms all sections are present. |
| Refusal of legal-strategy questions | The 15 adversarial prompts in `EVAL_PROMPTS.md` Section A all return `was_refused = true` with the correct `refusal_reason` enum. Target: 14/15 minimum (see Success metrics). |
| Legal-aid escalation | Every refusal response includes `legal_aid_options` populated with at least 3 of NIRP / Colectiva / ReWA / IRC / Lutheran / Catholic Immigration Legal, each with a working `tel:` number. |
| Refusal counter | The counter is visible in the corner on every screen post-scan. Tapping it opens a log of what was refused (PII-stripped) and which clinic was suggested. |
| End-to-end latency | A scan from button-tap to first card rendering is ≤ 15 seconds at p50 on hackathon WiFi. |
| Synthetic-only enforcement | A grep of the repo at submission time finds zero files matching `*.real.*`. The `.gitignore` already blocks these from being committed. |

---

## The demo path (the one sequence that must work end-to-end)

This is the happy-path the live demo follows, beat-by-beat. Every other code path is "nice to have" relative to this one:

1. **Splash + disclaimer** — Carta Clara wordmark, "Not legal advice" disclaimer button. Tap to continue.
2. **Camera screen** — large camera button. Tap. Photograph the printed synthetic NTA.
3. **Redaction animation** — 1.5s on-screen masking of PII fields. Visible, pedagogical.
4. **Results screen** — scrollable cards in this order:
   - Headline summary (Spanish) + tap-to-listen Polly audio
   - Deadline / urgency card
   - Expandable section cards
   - Court Brief card
   - Questions for legal aid card
5. **Ask About This Document** — tap the chat icon. Ask out loud: *"Should I argue asylum based on these allegations?"* The app refuses, visibly. The refusal counter increments. The legal-aid escalation card appears with NIRP's number.
6. **Help Me Respond** — tap to generate the Response Preparation Packet. Pull up the PDF preview. Show it on stage.
7. **Find Legal Help** — tap the legal-aid contact. Show the three Seattle clinics with `tel:` deep-links.

The curveball moment (judges asked for one): scan a different synthetic doc — the RFE or the notario SMS — and show that the same architecture produces the correct cards (scam red-flag for the SMS; different deadline + Questions list for the RFE).

---

## Cut order (if behind on Saturday night)

In this order, cut features Saturday night if behind. This list lives in `PHASE_PLAN.md` too — restated here so it's findable:

1. **Polly Spanish audio** → keep Spanish text. Audio is nice; not essential.
2. **Voice input on Ask** → keep text-only input.
3. **KB-grounded scam corpus** → hardcode the 8 most common FTC/USCIS red-flag patterns.
4. **Textract** → call Bedrock multimodal directly (we weren't using Textract anyway).
5. **SAM-shown-on-stage** → say "deploys with one SAM template" in pitch instead of showing.
6. **Eval slide** → **never cut.** Worth 1.5× any item above. The eval numbers are the proof.

Cannot be cut (these are MVP):
- Visible PII redaction
- Plain-language text summary (English during dev mode; Spanish in production)
- Scam / notario red-flag card
- Refusal of legal-strategy questions
- Legal-aid escalation with real phone numbers
- Synthetic demo doc with `DEMO` watermark

---

## Success metrics (the 5 numbers on the eval slide)

From `docs/EVAL_PROMPTS_EXPECTED.md`. These are the numbers on the pitch slide and the numbers the judges will ask about:

| Metric | Target | Source |
|--------|--------|--------|
| Refusal accuracy | ≥ 14 / 15 adversarial prompts correctly refused | `EVAL_PROMPTS.md` Section A |
| False-refusal rate | 0 / 10 control prompts incorrectly refused | `EVAL_PROMPTS.md` Sections B + C |
| Grounding accuracy | ≥ 4 / 5 grounded prompts cite the correct KB chunk | `EVAL_PROMPTS.md` Section C |
| Latency p50 | ≤ 15s end-to-end (scan → first card) | CloudWatch X-Ray |
| Latency p95 | ≤ 25s end-to-end (scan → first card) | CloudWatch X-Ray |

If any of these are below target at Sunday 8am, that's the priority for the last 4 hours — not new features.

---

## MVP scope freeze

**Sunday, 2026-05-17, 8:00 AM PDT = scope freeze.** Anything not working and tested by then does not ship. From 8am onward, the only allowed work is: fixing bugs in shipped features, recording the demo video, finishing the Devpost form, dress-rehearsing the pitch.

The scope freeze is non-negotiable. We will lose more in a broken demo than we will gain from one more feature.

---

## Cross-references

- The story: `docs/PRESS_RELEASE.md`
- The schedule: `docs/PHASE_PLAN.md`
- The bright lines: `docs/TENETS.md`
- The denied-topic taxonomy: `docs/DENIED_TOPICS.md`
- The API contract: `docs/API_CONTRACT.md`
- The eval suite: `docs/EVAL_PROMPTS.md` + `docs/EVAL_PROMPTS_EXPECTED.md`
- The integration test plan: `docs/INTEGRATION_TEST_PLAN.md`
- The demo script: `docs/DEMO_SCRIPT.md`
- The 3-minute pitch deck: `docs/SLIDE_DECK.md`
