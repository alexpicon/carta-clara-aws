# Carta Clara — Agent Task Queues

This is the canonical task queue for each persona on Carta Clara. Personas take tasks in order, log each in their own worklog, and report when their queue is complete.

**Format:** Each task has a unique ID, a status (todo/in_progress/done/blocked), a deliverable file path, and any dependencies on other personas' work.

Status legend:
- `[ ]` — todo
- `[~]` — in progress (one persona at a time per task)
- `[x]` — done
- `[!]` — blocked (see worklog for details)

---

## Sage — AI/ML Engineer

Owns: `backend/prompts/`, `kb-corpus/`
Worklog: `docs/worklog/sage.md`

### Queue

- [ ] **SAGE-01** — Write `backend/prompts/system_prompt.md` — base system prompt prepended to all Bedrock invocations. Enforces tenets: refuse legal/tax/medical strategy, no real documents, calm-but-urgent tone, cite sources, redact PII. Keep under 600 tokens.
- [ ] **SAGE-02** — Write `backend/prompts/extraction_prompt.md` — multimodal prompt that takes a document image and returns the JSON schema defined in `docs/synthetic-docs/NTA_demo.md` (the "What the Bedrock multimodal extraction should return" section). Must include explicit instruction to refuse extraction if document appears to contain real PII not behind redaction.
- [ ] **SAGE-03** — Write `backend/prompts/spanish_summary_prompt.md` — generates the headline 1–2 sentence Spanish summary + expandable section cards keyed to document sections. Must include the reading-level slider parameter `{beginner|intermediate|full}` controlling Spanish complexity. Reference text from NTA_demo for the headline summary as the target quality.
- [ ] **SAGE-04** — Write `backend/prompts/scam_check_prompt.md` — analyzes a separate text input (an SMS, email, business card, flyer) for notario/scam red-flag patterns. Returns list of detected flags, each with a citation to the relevant KB chunk (FTC or USCIS). Must NOT determine "this is a scam" with certainty; only "these patterns are commonly associated with scams."
- [ ] **SAGE-05** — Write `backend/prompts/response_packet_prompt.md` — generates the Response Preparation Packet content (translated summary, evidence checklist, pre-filled extension request, phone-call script, questions for legal aid, cover sheet). Output as Markdown for the iOS app to render as a printable PDF.
- [ ] **SAGE-06** — Curate `kb-corpus/uscis_avoid_scams.txt` — text from USCIS "Avoid Scams" public page. Use the live page content from uscis.gov/scams. Format as plain text, ~3-5KB. Include source URL as first line.
- [ ] **SAGE-07** — Curate `kb-corpus/ftc_immigration_scams.txt` — text from FTC immigration-scam consumer advisory page (ftc.gov). Same format.
- [ ] **SAGE-08** — Curate `kb-corpus/eoir_practice_manual_nta.txt` — relevant sections of the EOIR Practice Manual on Notice to Appear (justice.gov/eoir). Focus on what an NTA is, what hearings look like, respondent's rights.
- [ ] **SAGE-09** — Curate `kb-corpus/seattle_legal_aid.txt` — directory entry for Northwest Immigrant Rights Project, Colectiva Legal del Pueblo, Refugee Women's Alliance, International Rescue Committee SeaTac, Lutheran Community Services Northwest, Catholic Immigration Legal Services. Each entry: name, phone, address, hours, languages served, how to request a free consultation.
- [ ] **SAGE-10** — Curate `kb-corpus/immigration_terms_glossary_es.txt` — bilingual glossary of 30–50 immigration legal terms with plain Spanish definitions. Format: term (en) | término (es) | plain-Spanish definition.

When queue complete, post `QUEUE_COMPLETE` and standby.

### Round 2

- [ ] **SAGE-11** — Write `docs/synthetic-docs/notario_SMS_demo.md` — synthetic fake notario SMS text + formatting spec for the scam-check demo moment. Watermarked DEMO. Includes at least 5 of the 10 red-flag patterns from your `scam_check_prompt.md` so the demo deterministically surfaces flags.
- [ ] **SAGE-12** — Write `docs/synthetic-docs/RFE_demo.md` — synthetic Request for Evidence document for the "judge curveball" moment. Different doc type, exercises the same multimodal extraction + Spanish summary + response packet pipeline. Watermarked DEMO. Made-up names. Use a marriage-bona-fides RFE as the template.
- [ ] **SAGE-13** — Write `docs/EVAL_PROMPTS_EXPECTED.md` — for each of the 25 eval prompts in `docs/EVAL_PROMPTS.md`, document the expected refusal reason (one of the denied-topic names) and the expected citation chunk IDs (referencing the [CHUNK id]s in your kb-corpus files). Sunday's eval run becomes pass/fail not subjective.
- [ ] **SAGE-14** — Write `docs/KB_VERIFICATION_LIST.md` — table with columns `Claim | KB file | KB chunk ID | Live source URL`. One row per substantive claim in your kb-corpus files. The bio teammate uses this Saturday morning to spot-check every claim against the live .gov source before pitch.

When Round 2 queue complete, post `QUEUE_COMPLETE_R2` and standby.

---

## Koda — Backend Engineer

Owns: `backend/src/`, `backend/tests/`
Worklog: `docs/worklog/koda.md`

### Queue

- [ ] **KODA-01** — Read `docs/API_CONTRACT.md`. If unclear, escalate to Claudio.
- [ ] **KODA-02** — Implement real `backend/src/scan/handler.py`. Flow: accept base64 image → write to S3 with 1h tag → call Bedrock multimodal with extraction_prompt → parse structured JSON → call Bedrock with spanish_summary_prompt → call Polly to synthesize Spanish audio → write audio to S3 with presigned URL → return assembled response matching API_CONTRACT shape. Attach Guardrails (`guardrailIdentifier`, `guardrailVersion`) to every Bedrock invocation. Use env vars for IDs.
- [ ] **KODA-03** — Implement real `backend/src/ask/handler.py`. Flow: accept `{session_id, document_id, question, audio_base64?}` → if audio: Transcribe streaming → text → call Bedrock with KB.Retrieve grounding → if Guardrails intervenes: log refusal to DynamoDB and return safe-replacement text with escalation card → if allowed: return answer + citations. Refusal log entry: `{session_id, ts, question_hash, reason, ttl: now+3600}`.
- [ ] **KODA-04** — Verify `backend/src/refusal_log/handler.py` query is correct. If not, fix it.
- [ ] **KODA-05** — Write `backend/tests/test_scan.py` — pytest-style smoke test that exercises the scan handler end-to-end with a mock event (base64 of a small test image, e.g., a 100x100 placeholder).
- [ ] **KODA-06** — Write `backend/tests/test_ask.py` — pytest-style smoke test with mock event for `/ask`. Include one adversarial prompt to verify Guardrails refusal path returns the expected refusal log entry.
- [ ] **KODA-07** — Write `backend/tests/test_refusal_log.py` — verify the query returns correct count and recent entries.
- [ ] **KODA-08** — Add a `backend/src/_shared/` module if any helpers are duplicated across handlers (Bedrock client construction, S3 presign helper, prompt loader). Refactor minimally.
- [ ] **KODA-09** — Update `backend/README.md` with: (a) any new env vars required beyond template defaults, (b) how to run tests locally with `sam local invoke`, (c) how to view CloudWatch logs.

When queue complete, post `QUEUE_COMPLETE`.

Hard dependencies: SAGE-02 (extraction_prompt) must exist before KODA-02 can be smoke-tested with real prompts. Until then, write the handler with the prompt loader pattern (`open(path).read()`) — code is unchanged, just the prompt file is empty for now.

### Round 2

- [ ] **KODA-10** — Implement `POST /scan/packet`. The endpoint exists in `docs/API_CONTRACT.md` but is currently missing from `backend/template.yaml` and `backend/src/`. Add: (a) new function `ScanPacketFunction` in template.yaml, (b) new handler `backend/src/scan_packet/handler.py` that takes `{session_id, document_id}` and returns the `packet` object per API_CONTRACT, (c) smoke test `backend/tests/test_scan_packet.py`, (d) vendor `helpers.py` into the new handler dir. Use `response_packet_prompt.md` from Sage. Riku already built `ResponsePacketView` expecting this — closing the gap.
- [ ] **KODA-11** — Write `backend/scripts/vendor_prompts.sh` — shell script that copies `backend/prompts/*.md` into each handler dir before `sam build`. Make it idempotent. Add a `make build` shortcut in a `backend/Makefile` if useful. Update `backend/README.md` to recommend running this before every deploy.
- [ ] **KODA-12** — Update `backend/template.yaml` to use a tag-scoped S3 lifecycle rule for true 1-hour deletion of uploads (TENETS §7 hardening). Tag uploads with `ephemeral=true` from the handlers (which already tag, per KODA-02). Lifecycle rule: filter by tag `ephemeral=true`, expiration 1 day. Document the day-granularity limitation in code comments — true 1h deletion would require a separate cleanup Lambda.

When Round 2 queue complete, post `QUEUE_COMPLETE_R2` and standby.

---

## Riku — Mobile Engineer

Owns: `ios/`
Worklog: `docs/worklog/riku.md`

### Queue

- [ ] **RIKU-01** — Read `docs/API_CONTRACT.md` for response shapes. Read `docs/DEMO_SCRIPT.md` for screen flow and what each screen must demonstrate.
- [ ] **RIKU-02** — Create the iOS source tree at `ios/Sources/` with subfolders: `App/`, `Views/`, `Components/`, `Models/`, `Services/`. Use plain `.swift` files (Alex will create the Xcode project and drag these in).
- [ ] **RIKU-03** — Write `ios/Sources/App/CartaClaraApp.swift` — SwiftUI App entry point. Navigation root.
- [ ] **RIKU-04** — Write `ios/Sources/Models/Document.swift`, `Models/Refusal.swift`, `Models/PreparationPacket.swift` — Codable structs matching the API_CONTRACT response shapes.
- [ ] **RIKU-05** — Write `ios/Sources/Services/CartaClaraAPI.swift` — async/await REST client with methods `scan(image:) async throws -> ScanResult`, `ask(documentId:question:audioData:) async throws -> AskResult`, `refusalLog(sessionId:) async throws -> RefusalLog`. Base URL from `Configuration.plist` (Alex fills this in after SAM deploy).
- [ ] **RIKU-06** — Write `ios/Sources/Views/SplashView.swift` — full-screen Carta Clara wordmark + NSA disclaimer button + "Get started" CTA.
- [ ] **RIKU-07** — Write `ios/Sources/Views/CameraCaptureView.swift` — large rear-camera button, file-picker fallback, accessibility labels for VoiceOver. Use `PhotosPicker` + custom camera sheet with `AVCaptureSession`.
- [ ] **RIKU-08** — Write `ios/Sources/Views/RedactionAnimationView.swift` — 1.5s animation showing PII fields being masked. Pedagogical, visible, deliberately a bit slow so the audience sees it.
- [ ] **RIKU-09** — Write `ios/Sources/Views/ResultsView.swift` — scrollable card stack: SummaryCard, UrgencyCard, SectionCards (with reading-level slider binding), ScamRedFlagCard (conditional), CourtBriefCard, QuestionsCard.
- [ ] **RIKU-10** — Write `ios/Sources/Components/*.swift` — each card as a reusable component. Plus `RefusalCounter.swift` — floating UI element, taps to open RefusalLogView.
- [ ] **RIKU-11** — Write `ios/Sources/Views/AskChatView.swift` — chat surface, mic button primary (push-to-talk), text field secondary, refusal counter floating top-right, refusal events visibly increment counter. Use `AVAudioRecorder` for voice input.
- [ ] **RIKU-12** — Write `ios/Sources/Views/ResponsePacketView.swift` — printable preparation packet preview, "Share" button using `UIActivityViewController` for AirPrint / Save PDF.
- [ ] **RIKU-13** — Write `ios/Sources/Views/LegalHelpView.swift` — three Seattle clinic cards (hard-coded for v1 from `kb-corpus/seattle_legal_aid.txt`): NIRP, Colectiva, RWA. Each with `tel:` deep-link and `maps:` deep-link.
- [ ] **RIKU-14** — Write `ios/README.md` — step-by-step Xcode integration: (a) create new SwiftUI Xcode project named CartaClara with bundle ID, (b) drag `ios/Sources/` into the project navigator, (c) add Info.plist keys for `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSPhotoLibraryAddUsageDescription`, (d) build target iOS 17+, (e) run on physical iPhone (not simulator — camera doesn't work in simulator).
- [ ] **RIKU-15** — Write `ios/Configuration.plist` template — placeholder for `API_BASE_URL`. Alex fills in after SAM deploy.

When queue complete, post `QUEUE_COMPLETE`.

Hard dependencies: RIKU-04 + RIKU-05 require API_CONTRACT.md (Claudio writes this first).

### Round 2

- [ ] **RIKU-16** — Implement "Share Response Preparation Packet" via `UIActivityViewController`. Allow user to AirPrint, save as PDF, or Mail the packet. The packet content is already rendered in `ResponsePacketView` — this task wires up the share button. Generate the PDF from the packet view via `ImageRenderer` or `PDFKit`. Add accessibility hint "Share or print this packet for your legal aid appointment."
- [ ] **RIKU-17** — Add a "Try Demo Document" button on `SplashView` that loads the synthetic NTA from the app bundle (Alex will add the synthetic NTA JPEG to the app bundle later). Pressing it bypasses the camera and feeds the bundled image into the same scan pipeline. **This is the demo safety net** — if camera fails on stage, this button keeps the demo running. Hidden behind a small button labeled "Use demo document" so it doesn't confuse non-demo users.
- [ ] **RIKU-18** — Verify Codable field bindings against the latest `docs/API_CONTRACT.md`. Two known additions since RIKU-04: (a) `scam_check_summary_es` field added to `/scan` response, (b) `POST /scan/packet` endpoint will exist after KODA-10. Patch your `Models/Document.swift`, `Models/PreparationPacket.swift`, and `Services/CartaClaraAPI.swift` to match. Run a dry-decode against a sample response to catch any drift.

When Round 2 queue complete, post `QUEUE_COMPLETE_R2` and standby.

---

## Claudio — PM & Lead

Owns: `docs/` (most), root README, coordination
Worklog: `docs/worklog/claudio.md`

### Queue

- [x] CLAU-00 — Repo scaffolding done (existing files)
- [x] CLAU-01 — Strategy docs done (Press Release, Tenets, Phase Plan, Demo Script, FAQ, Eval Prompts, Denied Topics, NTA demo)
- [ ] **CLAU-02** — Write `docs/API_CONTRACT.md` — canonical REST contract. Unblocks Koda + Riku.
- [ ] **CLAU-03** — Write `docs/ARCHITECTURE.md` — system architecture with Mermaid diagram + AWS service-by-service rationale. For pitch slide 4.
- [ ] **CLAU-04** — Write `docs/SLIDE_DECK.md` — 6 slides in markdown with titles, bullets, speaker notes, visual suggestions.
- [ ] **CLAU-05** — Monitor all worklogs. Audit completed work for tenet violations and quality.
- [ ] **CLAU-06** — Update `docs/PHASE_PLAN.md` with role assignments once Alex confirms which teammate took which role.
- [ ] **CLAU-07** — Resolve cross-persona blockers as they arise.
- [ ] **CLAU-08** — When all queues complete, produce a unified status report and identify Saturday morning starting position.

### Round 2

- [ ] **CLAU-09** — Add Round 2 task definitions to AGENT_TASKS.md (this commit).
- [ ] **CLAU-10** — Write `docs/INTEGRATION_TEST_PLAN.md` — the Saturday-morning checklist for end-to-end smoke testing once the AWS console work is done (KB + Guardrail created, SAM redeployed with real IDs, prompts vendored).
- [ ] **CLAU-11** — Continue monitoring worklogs as Round 2 progresses. Arbitrate.

---

## How tasks become "done"

A task is done when:
1. The output file exists at the specified path
2. The worklog entry says COMPLETED
3. No tenet is violated
4. Claudio has not flagged a quality concern

Tasks are not done because "I wrote some code." They're done when the artifact is shippable.
