# Carta Clara — MVP Definition

This is the single source of truth for **what ships** as Carta Clara MVP. When you're tempted to add a feature, check the "Out of scope" list. When you're tempted to drop one, check "In scope (must-have)." When you need to know whether something is "done," check the "Acceptance criteria."

Everything here is consolidated from `PRESS_RELEASE.md`, `PHASE_PLAN.md`, `TENETS.md`, and `EVAL_PROMPTS_EXPECTED.md`. If this file conflicts with any of those, those win — open a PR to fix this file.

---

## One-line definition

**Carta Clara MVP** is a native iPhone app that photographs an English immigration document and returns, within 30 seconds, a plain summary, a deadline, a scam check, and a printable Response Preparation Packet for free legal aid — refusing every legal-strategy question and routing to a real lawyer instead.

> **Language status:** the app is **bilingual**. Right after the splash, the user picks Spanish or English at the LanguagePickerView; everything from that point on — camera tips, camera screen, results cards, UI chrome, errors, and Polly audio — respects the choice via `UIText.currentLanguage` flipping the active string bundle. Splash and the Language Picker itself remain English (they are pre-selection). The backend `/scan` accepts a `language` param (`en` or `es`) and produces all content in that language; the off-language summary field is left empty to save tokens. Korean / Hindi / others remain roadmap.

---

## In scope (must-have for the demo)

These are the features that ship, in priority order. The "Cut order" section below states what gets dropped first if we run out of time — these do **not** get dropped:

1. **Visible PII redaction animation** — the redaction animation plays on screen before the network request fires, narrating *"Your information is protected"* during the masking pass. (Note: the managed Bedrock Guardrail PII filter is still `PLACEHOLDER` for the hackathon; the animation is pedagogical and shows where that filter lives in the pipeline. The Results screen privacy banner is honest about what is real today — *"Your photo will be deleted in 1 hour. No account, no tracking."*)
2. **Plain-language summary** — text of what the document says in the user's chosen language (Spanish or English), tuned to the two-level reading slider (Plain / Detailed). iOS reads the field matching `selectedLanguage` (`summary_es` for Spanish, `summary_en` for English); the off-language field is left empty by the backend. Polly audio in the matching language is attached; audio is preferred but cuttable (see Cut order).
3. **Deadline / urgency card** — the next date the user must act, in the chosen language, with a verification line ("Verify this date against the document — Carta Clara can misread handwritten dates").
4. **Scam / notario red-flag card** — pattern-matches against the FTC + USCIS published warning signs. Conditional (only renders when patterns match). Cites the source.
5. **Court Brief card** — for NTAs only. Court name, address, what to expect, what to bring, what to wear. **Never** analyzes the judge.
6. **"Questions for legal aid" card** — a pre-written list of the right questions to ask, scoped to the specific document type.
7. **Response Preparation Packet** — printable, multi-section: title, what this says (translated summary), your deadline, an interactive documents-to-gather checklist (rendered on iOS), legal-aid phone-call script, questions to ask the lawyer, cover sheet that says "Bring this to your appointment. Your lawyer will write the official response." The packet is pre-fetched: AppState kicks off `/scan/packet` in the background the moment `/scan` succeeds (passing `extraction`, `summary`, and `language` so the call is text-only, ~10–14s) and caches the result on `cachedPacket`; ResponsePacketView checks the cache first and renders instantly on hit. *(Removed in this MVP: an extension-request letter template. Even with a "talk to your lawyer first" disclaimer, providing the template implied a recommendation that the user request more time — too close to legal strategy advice. Whether to request more time is a decision the legal-aid attorney makes.)*
8. **Refusal of legal-strategy questions** — every "should I…" question about strategy, eligibility, outcome, hearing attendance, ICE encounters, judge bias, or document authenticity is refused. The refusal is **visible** (counter in the corner, tappable to view log).
9. **Legal-aid escalation** — every refusal routes to at least one of NIRP / Colectiva / ReWA with a real phone number, address, and hours.
10. **Synthetic-only demo doc** — every screenshot, every video frame, every live demo uses a watermarked `DEMO – NOT A REAL CASE` document. Never a real one.

---

## Out of scope (explicit non-goals)

These are deliberate cuts. Each one is a "Think Big" talking point — we considered it, we have a reason, and we will articulate the reason on stage:

- **Languages other than the two we ship (Spanish and English).** Korean, Hindi, Mandarin, Tagalog are roadmap. We refuse to ship a language we can't validate against a native speaker on the team. (TENETS §9)
- **User accounts, login, signup, email field.** Ephemeral session only. No password reset flow, ever. (TENETS §7)
- **Persistent document storage.** S3 has a 1-hour TTL. We do not keep the user's documents. (TENETS §7)
- **Legal advice in any form.** No "you should…" answers. No form-selection. No admit/deny guidance. No eligibility opinions. No outcome predictions. (TENETS §3, bright lines)
- **Drafting substantive responses** to USCIS / EOIR / ICE / DHS / a court. The Response Preparation Packet *helps the user talk to a lawyer*; it does not replace the lawyer's response. (Bright line)
- **Judge analytics** or past-case matching of any kind. (Bright line)
- **Real immigration documents** in the demo, the video, the Devpost page, or anywhere user-visible. *Exception (temporary, team-internal only, TENETS §6 amended):* team members may scan documents they own/have lawful access to for accuracy testing. S3 1h TTL still applies. Real PII flows unmasked through Bedrock/Textract during this window; Guardrail PII filter is still `PLACEHOLDER`. **The bright line does NOT move for any externally-visible artifact.**
- **Android, web, or watch versions.** iPhone-only for MVP.
- **Offline mode.** The product requires network to call Bedrock. We will not fake an offline experience.
- **Document types beyond immigration** — utility notices, school letters, IRS mail, lease violations. All roadmap. The architecture is reusable; the MVP is immigration-only.

---

## Acceptance criteria ("done means…")

A feature is **done** when its row here is true. Not when the code compiles. Not when the screen renders. When the row is true.

| Feature | Done means… |
|---------|-------------|
| PII redaction animation | A live demo on a physical iPhone shows the redaction animation playing on screen before the network request fires. (The managed Guardrail PII filter is `PLACEHOLDER` today; the outbound payload is not yet masked at the model layer — the Results screen banner reflects this honestly: ephemerality and no-accounts, no claim of PII masking.) |
| Plain summary (text) | A synthetic NTA scan returns a headline summary in the language the user picked, that a team reviewer confirms is (a) correct, (b) at the Plain reading level when "Plain / Sencillo" is selected, (c) uses no untranslated legal jargon. Re-grade in Spanish against a native speaker for the Spanish path. |
| Summary audio | Tapping the audio button plays back the summary in the chosen language via the matching Polly neural voice (`Lupe` for Spanish), within 3 seconds of tap, audible without headphones in a quiet room. |
| Deadline card | The deadline card renders the exact date from the synthetic NTA (2026-10-15) with the verification line in the chosen language. |
| Scam red-flag card | Running the synthetic notario SMS through the app surfaces at least 3 FTC/USCIS-defined red flags, each with a citation chip linking back to a `kb-corpus/` source. |
| Court Brief card | Running the synthetic NTA surfaces a Court Brief naming "Seattle Immigration Court, 1000 Second Avenue, Suite 2900, Seattle, WA 98104" with a what-to-expect paragraph and zero analysis of any judge. |
| Questions for legal aid | At least 5 document-scoped questions render, each in the chosen language, each a question a lawyer would actually need answered (not generic). |
| Response Preparation Packet | The packet renders as a multi-section, printable view that fits on standard letter paper. Sections present: title, what this says (translated summary), your deadline (if applicable), documents to gather (interactive checklist on iOS), legal-aid phone-call script, questions for your lawyer, cover sheet. **Extension-request letter template intentionally excluded** — see in-scope note above. Pre-fetched via AppState `cachedPacket` so the view renders instantly from the cache. |
| Refusal of legal-strategy questions | The 15 adversarial prompts in `EVAL_PROMPTS.md` Section A all return `was_refused = true` with the correct `refusal_reason` enum. Target: 14/15 minimum (see Success metrics). |
| Legal-aid escalation | Every refusal response includes `legal_aid_options` populated with at least 3 of NIRP / Colectiva / ReWA / IRC / Lutheran / Catholic Immigration Legal, each with a working `tel:` number. |
| Refusal counter | The counter is visible in the corner on every screen post-scan. Tapping it opens a log of what was refused (PII-stripped) and which clinic was suggested. |
| End-to-end latency | A scan from button-tap to first card rendering is ≤ 15 seconds at p50 on hackathon WiFi. |
| Synthetic-only enforcement | A grep of the repo at submission time finds zero files matching `*.real.*`. The `.gitignore` already blocks these from being committed. |

---

## The demo path (the one sequence that must work end-to-end)

This is the happy-path the live demo follows, beat-by-beat. Every other code path is "nice to have" relative to this one:

1. **Splash + disclaimer** — Carta Clara wordmark with the open-envelope logo (SF Symbol `envelope.open.fill` with gradient + radial halo + drop shadow), "Not legal advice" disclaimer, and a single CTA: **Start scanning** (Spanish: **Empezar a escanear**). Tap to continue.
2. **Language picker** — user taps Spanish or English. Español is the primary (filled) button because the audience speaks Spanish. From here on, all UI chrome and content respect the choice via `UIText.currentLanguage`.
3. **Camera tips** — four short tips (good light, frame the page, hold steady, avoid glare) rendered in the chosen language. Tap **Open the camera** to continue.
4. **Camera screen** — large shutter button with corner brackets framing the document. Tap. Photograph the printed synthetic NTA. Confirm the photo (with a readability hint: "If you can read it, the app can read it too").
5. **Redaction animation** — 1.5s on-screen masking pass with the line *"Your information is protected."* Visible, pedagogical. (The animation copy stays; the Results banner is the more candid statement of what's real today.)
6. **Results screen** — scrollable cards in this order:
   - Privacy banner: *"Your photo will be deleted in 1 hour. No account, no tracking."*
   - Headline summary (in the chosen language) + tap-to-listen Polly audio
   - Deadline / urgency card
   - Expandable section cards with the two-level Plain / Detailed slider
   - Court Brief card
   - Questions for legal aid card
   - Bottom tertiary "Scan another document" / "Escanear otro documento" button
   - Top-right toolbar `arrow.clockwise.circle.fill` restart button on every post-scan screen
7. **Ask About This Document** — tap the chat icon. Ask out loud: *"Should I argue asylum based on these allegations?"* The app refuses, visibly. The refusal counter increments. The legal-aid escalation card appears with NIRP's number.
8. **Help Me Respond** — tap to open the Response Preparation Packet, which renders instantly from the `cachedPacket` pre-fetch. Show it on stage.
9. **Find Legal Help** — tap the legal-aid contact. Show the three Seattle clinics with `tel:` deep-links.
10. **Restart** — tap the top-right restart icon or the bottom "Scan another document" button. AppState.startFresh() pops the entire nav stack back to Splash.

The curveball moment (judges asked for one): scan a different synthetic doc — the RFE or the notario SMS — and show that the same architecture produces the correct cards (scam red-flag for the SMS; different deadline + Questions list for the RFE).

---

## Cut order (if behind on Saturday night)

In this order, cut features Saturday night if behind. This list lives in `PHASE_PLAN.md` too — restated here so it's findable:

1. **Polly audio** → keep the text in the chosen language. Audio is nice; not essential.
2. **Voice input on Ask** → keep text-only input.
3. **KB-grounded scam corpus** → hardcode the 8 most common FTC/USCIS red-flag patterns.
4. **Packet pre-fetch** → keep the on-demand `/scan/packet` call when the user taps "Help me respond"; lose the instant render, not the feature.
5. **SAM-shown-on-stage** → say "deploys with one SAM template" in pitch instead of showing.
6. **Eval slide** → **never cut.** Worth 1.5× any item above. The eval numbers are the proof.

Cannot be cut (these are MVP):
- Visible PII redaction animation (the Guardrail PII filter itself is `PLACEHOLDER` for the hackathon, but the animation and the candid Results banner both ship)
- Plain-language text summary in the user's chosen language (Spanish or English)
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
