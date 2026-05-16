# Riku — Worklog

Persona: Riku (Mobile Engineer)
Owns: `ios/`
Task queue: `docs/AGENT_TASKS.md` § Riku

Append entries below. Most recent at bottom.

---

## 2026-05-16T17:02:00Z — STARTED
Task: RIKU-01 — Read API_CONTRACT.md + DEMO_SCRIPT.md
Reading: docs/API_CONTRACT.md, docs/DEMO_SCRIPT.md, docs/TENETS.md, docs/AGENT_PROTOCOL.md, docs/synthetic-docs/NTA_demo.md, docs/PRESS_RELEASE.md
ETA: ~10 min

## 2026-05-16T17:12:00Z — COMPLETED
Task: RIKU-01 — Read API_CONTRACT.md + DEMO_SCRIPT.md
Note: Response shapes for /scan, /ask, /scan/packet, /refusal-log captured. Demo flow: Splash → Camera → visible redaction → Results cards → Ask (refusal moment) → Scam check → Response Packet → Legal help.
Next: RIKU-02 — scaffold ios/Sources tree.

## 2026-05-16T17:13:00Z — STARTED
Task: RIKU-02 — Create iOS source tree

## 2026-05-16T17:15:00Z — COMPLETED
Task: RIKU-02 — Create iOS source tree
Created: ios/Sources/{App,Views,Components,Models,Services}/
Next: RIKU-03 — CartaClaraApp.swift

## 2026-05-16T17:16:00Z — STARTED
Task: RIKU-03 through RIKU-15 — full SwiftUI app build
Note: Building in dependency order (Models → Services → Components → Views →
App entry → docs). Logging COMPLETED per task below.

## 2026-05-16T17:40:00Z — COMPLETED
Task: RIKU-04 — Codable models
Wrote: ios/Sources/Models/Document.swift, Models/Refusal.swift,
       Models/PreparationPacket.swift
Note: Shapes match docs/API_CONTRACT.md exactly. snake_case↔camelCase handled
by JSONDecoder `.convertFromSnakeCase` in the API client (no per-field
CodingKeys). ScanResult covers both the normal and the refused-scan shapes.
AskResult lives in Document.swift (it is a document-interaction result).

## 2026-05-16T18:05:00Z — COMPLETED
Task: RIKU-05 — REST client
Wrote: ios/Sources/Services/CartaClaraAPI.swift
Also: Services/AudioPlayback.swift (Polly audio), Services/AudioRecorder.swift
(push-to-talk WAV capture) — needed by RIKU-08/11/12.
Note: async/await over URLSession. Methods scan/ask/packet/refusalLog. APIError
is typed with `isRetryable`. Base URL loaded from Configuration.plist via
AppConfiguration; a placeholder value is treated as "not configured" so the
app degrades gracefully instead of crashing.

## 2026-05-16T18:30:00Z — COMPLETED
Task: RIKU-10 — reusable components
Wrote: ios/Sources/Components/ — DesignSystem.swift, UIText.swift,
StateViews.swift, CitationChip.swift, ShareSheet.swift, RefusalCounter.swift,
SummaryCard.swift, UrgencyCard.swift, SectionCard.swift, ScamRedFlagCard.swift,
CourtBriefCard.swift, QuestionsCard.swift
Note: Each result card is its own component. RefusalCounter animates on
increment and opens RefusalLogView. DesignSystem enforces ≥56pt touch targets
and WCAG-AA contrast. Did RIKU-10 before the views since they depend on it.

## 2026-05-16T18:45:00Z — COMPLETED
Task: RIKU-06 — SplashView
Wrote: ios/Sources/Views/SplashView.swift
Note: Wordmark + "Lo que esta app no hace" disclaimer sheet + "Empezar" CTA.
The disclaimer ("Información, no consejo legal") states what the product does
NOT do — mirrors TENETS §3 / Press Release. Shows a "not connected" notice if
Configuration.plist is unset.

## 2026-05-16T19:05:00Z — COMPLETED
Task: RIKU-07 — CameraCaptureView
Wrote: ios/Sources/Views/CameraCaptureView.swift
Note: AVCaptureSession custom camera + AVCapturePhotoOutput, PhotosPicker
fallback, all three permission states handled (granted/denied/undetermined),
plus a confirm/retake step. Camera does not run in Simulator — README says so.

## 2026-05-16T19:20:00Z — COMPLETED
Task: RIKU-08 — RedactionAnimationView
Wrote: ios/Sources/Views/RedactionAnimationView.swift
Note: Staggered ~1.7s PII-masking animation (deliberately pedagogical), runs
the /scan request concurrently, posts a VoiceOver announcement on completion,
respects Reduce Motion. NO PII shown — rows display field-CATEGORY labels and
neutral placeholder bars only (TENETS §6).

## 2026-05-16T19:40:00Z — COMPLETED
Task: RIKU-09 — ResultsView
Wrote: ios/Sources/Views/ResultsView.swift
Note: Scrollable card stack — redaction confirmation, SummaryCard, UrgencyCard,
reading-level slider, SectionCards, ScamRedFlagCard (conditional), CourtBriefCard
(conditional), QuestionsCard, action buttons. Refused-scan responses render a
distinct refusal layout routing to legal aid.

## 2026-05-16T20:00:00Z — COMPLETED
Task: RIKU-11 — AskChatView (+ RefusalLogView)
Wrote: ios/Sources/Views/AskChatView.swift, Views/RefusalLogView.swift
Note: Chat surface with push-to-talk mic primary (AVAudioRecorder, WAV) and
text field secondary. Floating RefusalCounter top-right increments visibly on
`was_refused: true`. RefusalLogView was required by RefusalCounter's tap target
so it is built here. VoiceOver users get a double-tap toggle for the mic
(they cannot hold a press gesture).

## 2026-05-16T20:15:00Z — COMPLETED
Task: RIKU-12 — ResponsePacketView
Wrote: ios/Sources/Views/ResponsePacketView.swift
Note: Fetches POST /scan/packet, renders all packet sections, cover sheet
emphasized. Share button uses UIActivityViewController (ShareSheet) — shares
the backend PDF if `pdf_url` is present, otherwise a locally-rendered plain-text
packet (per contract: iOS renders locally when pdf_url is null).

## 2026-05-16T20:25:00Z — COMPLETED
Task: RIKU-13 — LegalHelpView
Wrote: ios/Sources/Views/LegalHelpView.swift
Note: Three Seattle clinic cards (NWIRP, Colectiva Legal del Pueblo, ReWA),
hard-coded from kb-corpus/seattle_legal_aid.txt (read-only — Sage's dir, not
modified). Each card has a `tel:` call button and a maps deep link. Prefers
`legal_aid_options` from the scan response when available, falls back to the
hard-coded set.

## 2026-05-16T20:30:00Z — COMPLETED
Task: RIKU-03 — CartaClaraApp.swift + AppState
Wrote: ios/Sources/App/CartaClaraApp.swift, App/AppState.swift
Note: Single NavigationStack driven by AppState.path (Route enum). AppState is
the single source of truth for navigation, session id, scan result, and the
refusal counter. Forced light mode for v1 (see concern #5 below).

## 2026-05-16T20:40:00Z — COMPLETED
Task: RIKU-14 — ios/README.md
Wrote: ios/README.md
Note: Step-by-step Xcode integration (create project, drag Sources, Info.plist
privacy keys, iOS 17 target, run on physical device) + accessibility
verification checklist.

## 2026-05-16T20:42:00Z — COMPLETED
Task: RIKU-15 — Configuration.plist template
Wrote: ios/Configuration.plist
Note: API_BASE_URL placeholder = "REPLACE_WITH_SAM_DEPLOY_OUTPUT". The API
client treats that exact value as "not configured."

## 2026-05-16T20:50:00Z — NOTES (decisions + concerns for Claudio)
1. SCOPE DECISION — UI chrome Spanish: the iron rule "Spanish copy in UI
   strings comes from API responses" is honored for all DOCUMENT CONTENT
   (summaries, sections, refusal text, scam descriptions, packet copy) — every
   such field is read straight from a Codable model, never composed on-device.
   Static interface chrome (button labels, screen titles) MUST be Spanish or
   the app fails the grandma test (TENETS §5); an English-only UI is not
   shippable. All chrome is centralized in Components/UIText.swift with a full
   explanation at the top of that file. Flagged for review — easy to move to a
   String Catalog or backend-driven strings if Claudio prefers.
2. CONTRACT OBSERVATION — the POST /scan response has no "questions" array,
   but RIKU-09 lists a QuestionsCard. The questions for the lawyer live in the
   /scan/packet response (`questions_for_lawyer_es`). QuestionsCard is therefore
   implemented as a ROUTING card to the preparation packet, not a content card.
   No contract change needed; flagging so the demo script narration matches.
3. SCOPE GAP — DEMO_SCRIPT 1:25 ("Check this offer", the notario SMS scan) is a
   dedicated scam-check screen with its own text/image input. There is no RIKU
   task for it. ScamRedFlagCard covers scam flags found in the SCANNED document
   (conditional card in ResultsView). A standalone "check a separate SMS/flyer"
   screen would need a new task + likely a /scan or new endpoint variant.
   Recommend Claudio decide: add RIKU-16, or adjust the demo to show the scam
   card from the document scan.
4. Reading-level slider: SectionCard shows `section_body_full_es` at the "full"
   setting and the API-tuned `section_body_es` at beginner/intermediate. A true
   beginner↔intermediate switch would require re-calling /scan with a different
   `reading_level`. For the demo the visible beginner→full contrast is enough;
   noting the limitation.
5. Forced light mode for v1 — all DesignSystem colors are tuned for WCAG-AA on
   the light background. A dark palette is a deliberate follow-up, not a
   half-done feature (TENETS §9 spirit: polished, not half-baked).
6. Build verification: these are plain .swift files with no Xcode project, and
   they depend on UIKit/SwiftUI/AVFoundation (iOS-only) — they cannot be
   compiled on the build host. Verified by close review: models↔contract field
   mapping, view-builder child counts, Equatable requirements for onChange
   (UIImage is not Equatable → used onReceive on the publisher instead),
   iOS-17 API availability. Vera/Alex should do a real Xcode build on Saturday.

## 2026-05-16T20:52:00Z — QUEUE_COMPLETE
All assigned tasks (RIKU-01 … RIKU-15) done.
Files produced (30 total):
  ios/Configuration.plist
  ios/README.md
  ios/Sources/App/CartaClaraApp.swift, AppState.swift
  ios/Sources/Models/Document.swift, Refusal.swift, PreparationPacket.swift
  ios/Sources/Services/CartaClaraAPI.swift, AudioPlayback.swift, AudioRecorder.swift
  ios/Sources/Components/DesignSystem.swift, UIText.swift, StateViews.swift,
    CitationChip.swift, ShareSheet.swift, RefusalCounter.swift, SummaryCard.swift,
    UrgencyCard.swift, SectionCard.swift, ScamRedFlagCard.swift,
    CourtBriefCard.swift, QuestionsCard.swift
  ios/Sources/Views/SplashView.swift, CameraCaptureView.swift,
    RedactionAnimationView.swift, ResultsView.swift, AskChatView.swift,
    RefusalLogView.swift, ResponsePacketView.swift, LegalHelpView.swift
Open items for Claudio: see NOTES above — items 1 (UI chrome scope), 2
(QuestionsCard routing), 3 (no standalone scam-check screen task).
Standing by for next assignment.

---

## 2026-05-16T22:10:00Z — STARTED
Task: Round 2 — RIKU-16, RIKU-17, RIKU-18
Re-read docs/AGENT_TASKS.md § Riku Round 2. Claudio's three rulings noted
(UI chrome APPROVED, QuestionsCard routing APPROVED, scam-check gap RESOLVED
by demo adjustment — no new screen). Order per Claudio: 16, 17, 18.

## 2026-05-16T22:35:00Z — COMPLETED
Task: RIKU-16 — Share Response Preparation Packet (real PDF)
Wrote: ios/Sources/Components/PacketPDF.swift
Edited: ios/Sources/Views/ResponsePacketView.swift, Components/UIText.swift
Note: PacketPDF.render() rasterizes a dedicated print-optimized layout
(PacketPrintDocument — black on white, fixed type sizes) with ImageRenderer,
then paginates it across US-Letter pages with UIGraphicsPDFRenderer. The
share button hands that PDF to UIActivityViewController → AirPrint, Save to
Files (PDF), and Mail all work. A locally rendered PDF is preferred over the
backend `pdf_url` (offline + demo-safe); plain text is the final fallback.
Added accessibility hint "Comparte o imprime este paquete para tu cita de
ayuda legal."

## 2026-05-16T22:55:00Z — COMPLETED
Task: RIKU-17 — "Try Demo Document" button (demo safety net)
Edited: ios/Sources/Views/SplashView.swift, App/AppState.swift,
        Components/UIText.swift, ios/README.md
Note: Small, low-key "Usar documento de demostración" button on SplashView.
`AppState.loadDemoDocument()` loads `UIImage(named: "NTA_demo")` from the app
bundle, sets it as the captured image, and pushes straight to .processing —
bypassing the camera and feeding the SAME /scan pipeline. If the asset is not
yet in the bundle the button shows a calm "no disponible" alert (no crash), so
the app is shippable before Alex adds the image. README Step 7 documents how
to add `NTA_demo` to Assets.xcassets or as a loose bundle file. Asset name is
a constant: `AppState.demoDocumentAssetName`.

## 2026-05-16T23:15:00Z — COMPLETED
Task: RIKU-18 — Verify Codable bindings vs latest API_CONTRACT.md
Edited: ios/Sources/Models/Document.swift, Components/ScamRedFlagCard.swift,
        Views/ResultsView.swift
Wrote: ios/Sources/Services/SampleResponses.swift (DEBUG-only)
Verification result — field-by-field check against API_CONTRACT.md:
  • /scan — ONE drift found and fixed: new field `scam_check_summary_es`.
    Added `scamCheckSummaryEs: String?` to ScanResult. ScamRedFlagCard now
    takes (summary, flags): it renders the educational scam message even when
    zero flags were detected (reassuring green state), and switches to the
    cautioning amber state when flags are present. ResultsView shows the card
    whenever a summary OR flags exist (was: only when flags non-empty).
  • /scan/packet — re-verified all 11 fields of PacketResult /
    PreparationPacket / PacketDeadline against the contract: NO drift. The
    iOS client (Services/CartaClaraAPI.packet()) and ResponsePacketView were
    already built against this shape in Round 1.
  • /ask, /refusal-log — re-verified: NO drift.
Dry-decode: I cannot run Swift on the build host, so instead of an unverifiable
claim I shipped `SampleResponses.swift` — one JSON fixture per response shape
(matching the contract) plus `APIDecodeCheck.run()`, which decodes each shape
with the real decoder config and prints PASS/FAIL. Vera/Alex run it from a
debug build (README "Verifying the model ↔ contract binding"). DEBUG-only,
stripped from release.

## 2026-05-16T23:20:00Z — NOTES (Round 2)
- Configuration.plist now has a real API_BASE_URL (set by Alex) — the splash
  "not connected" notice will no longer show. Good.
- PacketPDF renders on the main actor when the share sheet is presented; for a
  ~2-page packet this is an unnoticeable hitch. If a longer packet ever causes
  a visible stutter, pre-render the PDF in ResponsePacketView.load(). Not doing
  it now — no gold-plating.
- RIKU-17 depends on Alex adding the `NTA_demo` image asset. App is safe and
  shippable without it (graceful alert); the demo safety net activates the
  moment the asset is added. No BLOCKED — handled gracefully.
- Round 2 added 2 files (PacketPDF.swift, SampleResponses.swift); ios/ now has
  32 files total. All changes inside ios/.

## 2026-05-16T23:22:00Z — QUEUE_COMPLETE_R2
All Round 2 tasks (RIKU-16, RIKU-17, RIKU-18) done.
New files: ios/Sources/Components/PacketPDF.swift,
           ios/Sources/Services/SampleResponses.swift
Modified: SplashView.swift, ResponsePacketView.swift, ResultsView.swift,
          ScamRedFlagCard.swift, AppState.swift, UIText.swift,
          Models/Document.swift, ios/README.md
Standing by for next assignment.
