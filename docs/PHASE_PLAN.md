# Carta Clara — Phase Plan

**Hackathon window:** Friday evening → Sunday afternoon. ~36 working hours after sleep.

**Cardinal rule:** Sunday 8am = scope freeze. Anything not working and tested by then does not ship.

---

## Phase map

| Phase | Window | Goal | Exit criteria |
|-------|--------|------|---------------|
| 0 | Fri 6pm–9pm | Setup, model access requests | All members can run `aws sts get-caller-identity` |
| 1 | Fri 9pm–11pm | Press Release written, foundation deployed | PR aligned by team; SAM deployed; iOS project builds |
| — | Fri 11pm–Sat 7am | **SLEEP** | — |
| 2 | Sat 7am–12pm | Vertical slice end-to-end | Snap on iPhone → real Bedrock response on screen |
| 3 | Sat 12pm–5pm | Bedrock layer (KB, Guardrails, prompts) | Spanish output works, refusal works, scam check works |
| 4 | Sat 12pm–5pm (parallel) | iOS UX (all 7 screens) | All cards render with mock data |
| 5 | Sat 5pm–10pm | Integration + voice + Ask About This Doc | Voice in + voice out + chat all working end-to-end |
| — | Sat 10pm–Sun 7am | **SLEEP** | — |
| 6 | Sun 7am–11am | Polish + eval slide + dress rehearsals | 3 dress rehearsals done, eval numbers locked |
| 7 | Sun 11am–2pm | Submission package | Devpost submitted, video uploaded, repo public |
| 8 | Sun afternoon | **Pitch + Q&A** | — |

---

## Phase 0 — Setup (Fri 6pm–9pm, ~3h)

**Owner:** Whole team kickoff.

### Goals
- AWS access verified for everyone who needs it.
- Bedrock model access requested (this is the longest-pole item — if it doesn't approve by Saturday morning, the demo is in trouble).
- All tooling installed.
- Repo on GitHub, everyone has push access.

### Tasks
- [ ] Create GitHub repo `carta-clara`. Push this scaffolding. Add team as collaborators.
- [ ] Each member runs `aws configure` against the team AWS account.
- [ ] **Request Bedrock model access** in console (us-west-2):
  - Anthropic Claude Sonnet 4.x
  - Amazon Nova Pro
  - Amazon Titan Embed Text v2
  - (Optional) Nova Sonic
- [ ] Install AWS SAM CLI: `brew install aws-sam-cli`
- [ ] iOS engineer: confirm Xcode 16+ installed, Apple Developer account active, iPhone connected to laptop for on-device testing.
- [ ] Create a Slack/Discord channel for the weekend. One thread per phase.
- [ ] Print the **synthetic NTA-style demo document** (alternate: also a synthetic RFE for the curveball moment).

### Exit
- Every team member can run `aws sts get-caller-identity` from the CLI.
- Bedrock console shows "Access granted" for the four models.
- Repo is pushed.

---

## Phase 1 — Foundation (Fri 9pm–11pm, ~2h)

**Owner:** PM writes PR; Backend engineer deploys SAM; iOS engineer creates Xcode project.

### Goals
- **Press Release written and agreed by the team.** No code before alignment.
- Backend infrastructure deployed in AWS via SAM.
- iOS project skeleton runs on a real iPhone.

### Tasks

**PM / Pitch lead:**
- [ ] Finalize `docs/PRESS_RELEASE.md` (draft is in repo — edit to match team voice).
- [ ] Read aloud to team. Get explicit agreement on every paragraph. Disagreements get resolved before code.

**Backend engineer:**
- [ ] `cd backend && sam build`
- [ ] `sam deploy --guided` — answer prompts: stack name `carta-clara-mvp`, region `us-west-2`, capabilities `CAPABILITY_IAM`, save config yes.
- [ ] Verify in AWS console: S3 bucket, DynamoDB table, API Gateway, 3 Lambda functions all exist.
- [ ] Copy the API Gateway URL from the deploy output. Share with iOS engineer.

**iOS engineer:**
- [ ] `cd ios && open` create new SwiftUI iOS app project named `CartaClara`.
- [ ] Set bundle ID, signing team.
- [ ] Build to physical iPhone — confirm it installs and runs.
- [ ] Add `Info.plist` permissions: `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSPhotoLibraryAddUsageDescription`.

### Exit
- PR signed off by team.
- SAM stack deployed. API URL known.
- iOS app installs on a real iPhone and shows a "Hello Carta Clara" screen.
- **SLEEP at 11pm.**

---

## Phase 2 — Vertical Slice (Sat 7am–12pm, ~5h)

**Owners:** Backend + iOS, working in tandem.

**Goal:** One single end-to-end path works. Snap → S3 → Bedrock multimodal → JSON → display on iPhone. No polish, no Spanish, no audio, no chat — just prove the pipeline.

### Tasks

**Backend engineer:**
- [ ] Implement `src/scan/handler.py`:
  - Accept base64 image from POST body
  - PutObject to S3 with 1h TTL tag
  - Call Bedrock multimodal (`anthropic.claude-sonnet-4-x-v1:0` or `amazon.nova-pro-v1:0`) with the image
  - Prompt: "Extract structured JSON: {document_type, sender, dates, court, deadline, important_terms}. Do not invent any field."
  - Return JSON to caller
- [ ] Test from `curl` with a base64-encoded synthetic NTA. Verify JSON shape.

**iOS engineer:**
- [ ] Camera capture screen (`UIImagePickerController` or `PhotosPicker`).
- [ ] On capture: base64-encode image, `URLSession` POST to `${API_URL}/scan`.
- [ ] Receive JSON, render a basic results screen showing extracted fields raw (English text — Spanish comes Phase 3).

**Bedrock / RAG engineer (in parallel):**
- [ ] Begin curating `kb-corpus/`. Pull these public docs:
  - USCIS "Avoid Scams" page text
  - FTC immigration-scam guidance
  - EOIR Practice Manual excerpts (NTA section, RFE section)
  - Seattle Office of Immigrant and Refugee Affairs resource page
  - NIRP, Colectiva Legal del Pueblo, RWA, IRC SeaTac contact info
- [ ] Format each as plain text, ~5KB max per file.

### Exit
- Take a photo of the printed synthetic NTA on the iPhone.
- See real Bedrock-extracted JSON render on the phone screen within ~15 seconds.
- KB corpus has 10–15 source documents ready to ingest.

---

## Phase 3 — Bedrock Layer (Sat 12pm–5pm, ~5h)

**Owners:** Backend + Bedrock / RAG.

### Goals
- Knowledge Base ingested and queryable.
- Guardrails attached and refusing legal-strategy questions.
- Spanish summary output works.
- Scam-pattern detection works.

### Tasks

**Bedrock / RAG engineer:**
- [ ] In Bedrock console: create Knowledge Base "carta-clara-kb", S3 data source = `kb-corpus/`.
- [ ] Embeddings: Titan Embed Text v2. Vector store: OpenSearch Serverless (managed, easiest).
- [ ] Run sync. Wait for "Available" state.
- [ ] Test retrieval in console with sample query: *"What are notario red flags?"* Verify citations returned.
- [ ] Create Bedrock Guardrail "carta-clara-guard":
  - **Denied topics** (10 entries): legal strategy, hearing skip, asylum eligibility, deportation prediction, judge bias claims, ICE-encounter scripts, court-statement advice, admit/deny allegations, "should I sign", "should I lie"
  - **PII filter**: NAME (anonymize), EMAIL (block), PHONE (anonymize), SSN (block), ADDRESS (anonymize)
  - **Contextual grounding**: ON, threshold 0.7
- [ ] Run 20 adversarial prompts (provided in `docs/EVAL_PROMPTS.md` — Sage will add). Confirm 20/20 refuse.

**Backend engineer:**
- [ ] Update `scan` Lambda to call KB.Retrieve for grounded explanation alongside the extraction call.
- [ ] Add Spanish translation prompt: "Translate this summary into 5th-grade-reading-level Spanish. Use everyday vocabulary, not legal terminology."
- [ ] Attach Guardrails to all Bedrock invocations via `guardrailIdentifier`.
- [ ] Add Polly call: synthesize Spanish summary text using voice `Lupe` (generative if available, neural fallback). Return audio URL.

### Exit
- POST /scan returns: extraction JSON + plain-English summary + Spanish summary + Polly audio URL + scam-red-flag list (if applicable) + citation IDs.
- 20/20 adversarial prompts refused with proper safe-replacement text.

---

## Phase 4 — iOS UX (Sat 12pm–5pm parallel, ~5h)

**Owner:** iOS engineer.

### Goals
- All 7 screens implemented with mock data.
- Visible redaction animation.
- Refusal counter component.
- Card layout that scales from short docs to long docs.

### Screens (from `docs/ARCHITECTURE.md`)
1. **Splash + disclaimer** — full screen, big Carta Clara wordmark, "Not legal advice" disclaimer button to continue.
2. **Camera capture** — large rear-camera button, secondary "Pick from library" link.
3. **Redaction in progress** — 1.5s animation showing PII fields being masked. Pedagogical, not technical.
4. **Result screen** — scrollable cards:
   - Headline summary card + tap-to-listen Spanish audio button
   - Urgency card (deadline + verification line)
   - Expandable section cards (one per part of the document)
   - Reading-level slider
   - Scam red-flag card (conditional)
   - Court Brief card
   - "Questions for legal aid" card
5. **Ask About This Document** — chat surface, mic button primary, text field secondary, refusal counter floating in corner.
6. **Help Me Respond → Response Preparation Packet** — printable, multi-section.
7. **Find Legal Help** — three real Seattle clinics with phone / address / hours.

### Component checklist
- [ ] `RedactionView` — animated PII masking
- [ ] `SummaryCard` — headline + audio button
- [ ] `UrgencyCard` — deadline + verification
- [ ] `SectionCard` — expandable, with reading-level binding
- [ ] `ScamRedFlagCard` — conditional, with citation chips
- [ ] `CourtBriefCard` — court name + address + what-to-expect
- [ ] `QuestionsCard` — list of questions for legal aid
- [ ] `RefusalCounter` — floating UI element, taps to open refusal log
- [ ] `AskChatView` — mic + text, scoped to document
- [ ] `ResponsePacketView` — printable preparation packet
- [ ] `LegalHelpView` — clinic list with `tel:` deep-link

### Exit
- All 7 screens implemented. Each renders with mock data.
- Ready to plug in real backend in Phase 5.

---

## Phase 5 — Integration + Voice + Chat (Sat 5pm–10pm, ~5h)

**Owners:** iOS + Backend.

### Goals
- iOS calls real backend for all 3 endpoints.
- Voice input (Transcribe streaming) works.
- Polly audio plays back in iOS.
- Ask About This Document chat works end-to-end with Guardrails-enforced refusals.
- Response Preparation Packet generates real content.

### Tasks

**Backend engineer:**
- [ ] Implement `src/ask/handler.py`:
  - Accept `{document_id, question}` (text mode) or accept audio bytes (voice mode)
  - If audio: call Transcribe streaming, get transcript
  - Call Bedrock with question + KB.Retrieve + Guardrails
  - If refusal: log to DynamoDB, return refusal + safe alternative + nearest legal aid
  - Return JSON: `{answer, citations, was_refused, refusal_id?}`
- [ ] Implement `src/refusal_log/handler.py`:
  - Return count and list of recent refusals for the current session
- [ ] Add `Help Me Respond` action to `scan` Lambda — generates the preparation-packet content.

**iOS engineer:**
- [ ] Wire Camera screen → POST /scan → render Result cards with real data.
- [ ] Add `AVAudioRecorder` for voice input on the Ask screen.
- [ ] Add `AVPlayer` for Polly audio playback on the Summary card.
- [ ] Refusal counter polls /refusal-log on session start, increments on refusal event.

### Exit
- Full end-to-end demo flow works on iPhone, against real AWS backend.
- All 7 screens populated with real data.
- Voice in / voice out tested in a real room (not just simulator).
- **SLEEP at 10pm.** Tired teams ship broken demos.

---

## Phase 6 — Polish (Sun 7am–11am, ~4h)

**Owners:** Whole team.

### Goals
- Eval slide locked.
- Pitch dress-rehearsed 3x.
- Backup demo video recorded.
- Validation outreach replies (if any) folded in.

### Tasks
- [ ] **Run the eval suite.** 20 adversarial prompts + 3 synthetic NTAs + 3 fake notario messages + 5 grounded-term queries + latency p50/p95. Put the 5 numbers on a slide.
- [ ] **Re-test demo on hackathon WiFi** if you can get to the venue early. Latency can change.
- [ ] **Record a backup 90-second video** of the demo working. If live demo fails on stage, play this.
- [ ] **Pitch dress rehearsal x3** — full 3-minute timed runs with the timer visible. Time every beat.
- [ ] **Validation outreach follow-up** — call NIRP, Colectiva, RWA again. Any reply, even one sentence, goes on a slide.
- [ ] **Finalize `docs/FAQ.md`** — the 6–8 hardest judge questions with rehearsed answers.
- [ ] **Print 3 copies of the Response Preparation Packet** on real paper. Physical artifacts win demos.

### 8am scope freeze
**At 8am Sunday, no new features ship. Period.** If something's broken, fix it; don't add.

### Exit
- Eval slide done. 5 numbers visible.
- Backup video recorded.
- 3 pitch dress rehearsals complete.
- FAQ.md final.

---

## Phase 7 — Submission (Sun 11am–2pm, ~3h)

**Owner:** PM, with team support.

### Tasks
- [ ] Final 3-minute demo video recorded (screen recording from iPhone via QuickTime + voiceover).
- [ ] Upload to YouTube as unlisted. Get URL.
- [ ] Devpost submission page:
  - Project name: Carta Clara
  - Tagline: from `docs/PRESS_RELEASE.md` headline
  - Description: condensed from PR
  - Built With: list every AWS service used
  - GitHub repo URL (make public)
  - Demo video URL
  - Screenshots (5 from the iPhone screens)
- [ ] Architecture diagram exported as PNG.
- [ ] Submit Devpost form before deadline.
- [ ] (Optional) TestFlight build uploaded.

### Exit
- Devpost form submitted, confirmation email received.
- Repo public on GitHub.
- Video live on YouTube.

---

## Phase 8 — Pitch (Sun afternoon)

- Show up early.
- Test projector adapter / HDMI on the actual stage screen.
- One person owns the iPhone. One person owns the laptop / slides.
- Run the demo script verbatim. Don't improvise.
- Answer questions from `docs/FAQ.md`. If a question isn't on the list, take 2 seconds, then answer honestly.
- Close on the line in the press release: *"We built Carta Clara with gratitude — for the people who got us here, and for the moments AI should be careful, cited, and humble."*

---

## Risk register

| Risk | Mitigation | Owner | Trigger |
|------|------------|-------|---------|
| Bedrock model access not approved by Saturday morning | Request Friday 6pm. Have OpenAI fallback prompt ready in `backend/src/` (do not commit; use only if necessary). | Backend | Sat 8am: check access |
| Polly Spanish voice sounds robotic | Test both `Lupe` (neural) and `Mia` if available. Pre-record a Spanish snippet as last-resort fallback. | Bedrock | Sat 6pm: voice review |
| KB sync stuck | Re-run sync; reduce corpus to 10 files; if still stuck, hard-code the scam-red-flag patterns in code. | Bedrock | Sat 2pm: check status |
| Live demo wifi fails | Use phone hotspot; backup video plays. | PM | Sun afternoon |
| Guardrails refuse too aggressively | Tune threshold from 0.7 → 0.6; specifically test the "what does this document say" path to make sure it's not refused. | Bedrock | Sat 4pm: full pass test |
| iOS app crashes on camera capture | Test on physical device early Phase 2. Don't trust the simulator. | iOS | Sat 9am: device test |
| One teammate flakes | Reassign their phase tasks to whoever has bandwidth. Tenets and PR keep everyone aligned. | PM | Continuous |

---

## Communication rituals

- **Phase boundary check-ins** — 5 min at the start of each phase. What's done, what's blocked, what's next.
- **Saturday 6pm dress rehearsal** — first full demo run, even if rough. Identifies what's missing for Sunday morning.
- **Sunday 8am scope freeze meeting** — explicit declaration. Anything not done gets cut.
- **Sunday 12pm final dress rehearsal** — last polish opportunity.

---

## Team role split

(Assumes 3 people. Adapt if 2 or 4.)

| Role | Owns | Background needed |
|------|------|-------------------|
| **iOS lead + PM** (Alex) | SwiftUI app, demo, pitch, outreach | Swift / iOS shipping |
| **Backend + Infrastructure** | SAM, Lambda, Bedrock SDK, integration | Python or Node, AWS familiarity |
| **Bedrock / RAG / Demo doc** | KB curation, Guardrails config, prompts, synthetic doc design, eval | Prompt engineering, careful reading |

If you have a 4th person: split iOS UX from PM. PM owns slides + script + outreach; UX-iOS owns SwiftUI implementation.

If you only have 2: Alex owns iOS + PM + demo doc + outreach. Teammate owns Backend + Bedrock + KB. Drop the Court Brief and Response Preparation Packet to nice-to-have.

---

## Cut order if you fall behind

In the order you should cut features Saturday night if you're behind:

1. Polly Spanish audio → keep Spanish *text*. Voice is nice; not essential.
2. Voice input on Ask About This Document → keep text-only.
3. KB-grounded scam corpus → hardcode 8 most common red-flag patterns.
4. Textract → call Bedrock multimodal directly (you weren't using Textract anyway).
5. CloudFormation/SAM → say "next step" in pitch instead of showing.
6. Eval slide → **never cut this.** Worth 1.5 of any item above.

Must-haves you cannot cut:
- Visible PII redaction.
- Spanish text summary.
- Scam/notario red-flag card.
- Refusal of legal-strategy questions.
- Legal-aid escalation with real numbers.
- Synthetic demo doc with `DEMO` watermark.
