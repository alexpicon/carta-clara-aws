# Carta Clara — iOS App

Native iOS app for Carta Clara. SwiftUI, target **iOS 17+**, Swift 5.9+.

These source files are written as plain `.swift` files. They are **not** an
Xcode project yet — Alex creates the project once and drags the sources in.
This README is the step-by-step.

---

## What's in here

```
ios/
├── Configuration.plist        ← API base URL (you fill this in after sam deploy)
├── README.md                  ← this file
└── Sources/
    ├── App/
    │   ├── CartaClaraApp.swift     App entry point + navigation root
    │   └── AppState.swift          Navigation + session state (single source of truth)
    ├── Models/
    │   ├── Document.swift          Codable models for /scan and /ask
    │   ├── Refusal.swift           Codable models for /refusal-log
    │   └── PreparationPacket.swift Codable models for /scan/packet
    ├── Services/
    │   ├── CartaClaraAPI.swift     async/await REST client + config loader
    │   ├── AudioPlayback.swift     Polly audio playback (AVPlayer)
    │   └── AudioRecorder.swift     Push-to-talk voice capture (AVAudioRecorder)
    ├── Components/
    │   ├── DesignSystem.swift      Colors, spacing, card chrome, button styles
    │   ├── UIText.swift            Centralized UI chrome strings (see note below)
    │   ├── StateViews.swift        Loading / error / empty states, demo badge
    │   ├── CitationChip.swift      Tappable source citations + flow layout
    │   ├── ShareSheet.swift        UIActivityViewController wrapper
    │   ├── RefusalCounter.swift    Floating refusal counter
    │   ├── SummaryCard.swift       Headline summary + audio
    │   ├── UrgencyCard.swift       Deadline card
    │   ├── SectionCard.swift       Expandable document-section card
    │   ├── ScamRedFlagCard.swift   Scam / notario red-flag card
    │   ├── CourtBriefCard.swift    "What to expect at this courthouse" card
    │   └── QuestionsCard.swift     Routes to the preparation packet
    └── Views/
        ├── SplashView.swift            Wordmark, disclaimer, "Empezar" CTA
        ├── CameraCaptureView.swift     Camera capture + photo-library fallback
        ├── RedactionAnimationView.swift Visible PII redaction + runs the scan
        ├── ResultsView.swift           Scrollable result card stack
        ├── AskChatView.swift           Voice/text chat + refusal counter
        ├── RefusalLogView.swift        The refusal log
        ├── ResponsePacketView.swift    Preparation packet + share/print
        └── LegalHelpView.swift         Free Seattle legal-aid clinics
```

---

## Step 1 — Create the Xcode project

1. Xcode → **File ▸ New ▸ Project… ▸ iOS ▸ App**.
2. Settings:
   - **Product Name:** `CartaClara`
   - **Organization Identifier:** `pe.tabo` (or your team's identifier)
   - **Bundle Identifier:** `pe.tabo.CartaClara`
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** None (no Core Data)
3. Save the project — recommended location: `ios/CartaClara.xcodeproj` inside
   this folder, or alongside it. Either works.
4. Xcode generates a starter `CartaClaraApp.swift` and `ContentView.swift`.
   **Delete both** from the project navigator (Move to Trash) — our
   `Sources/App/CartaClaraApp.swift` replaces them.

## Step 2 — Add the source files

1. In Finder, locate `ios/Sources/`.
2. Drag the **`Sources` folder** into the Xcode project navigator, dropping it
   under the `CartaClara` group.
3. In the dialog:
   - ✅ **Copy items if needed** — leave UNCHECKED if `Sources/` already sits
     inside the project folder; CHECK it otherwise.
   - ✅ **Create groups** (not folder references).
   - ✅ **Add to target: CartaClara**.
4. Drag **`Configuration.plist`** into the project the same way. Confirm its
   **Target Membership** includes `CartaClara` (File Inspector, right panel) —
   it must be copied into the app bundle.

## Step 3 — Set the deployment target

1. Select the project ▸ **CartaClara** target ▸ **General**.
2. **Minimum Deployments → iOS `17.0`**.
   (The app uses `AVAudioApplication.requestRecordPermission`, `.symbolEffect`,
   and the `Layout` protocol — all iOS 16/17 APIs. 17.0 is the floor.)

## Step 4 — Add the privacy usage descriptions

The app will **crash on first camera/mic use** without these. Add them to the
target's **Info** tab (Xcode 15+ shows Info keys under the target), or to a
custom `Info.plist`:

| Key | Suggested value (English; iOS shows it at the system prompt) |
|-----|--------------------------------------------------------------|
| `NSCameraUsageDescription` | `Carta Clara uses the camera so you can photograph a document to understand it.` |
| `NSMicrophoneUsageDescription` | `Carta Clara uses the microphone so you can ask questions about your document with your voice.` |
| `NSPhotoLibraryAddUsageDescription` | `Carta Clara can save items to your photo library.` |

Notes:
- `NSCameraUsageDescription` and `NSMicrophoneUsageDescription` are **required** —
  the app requests both at runtime.
- `NSPhotoLibraryAddUsageDescription` is listed for completeness. The photo
  picker uses `PhotosPicker` (PhotosUI), which runs out-of-process and needs
  **no** photo-library permission for reading. Keep this key only if a future
  feature writes to the library; it is harmless to include.
- These strings are the only English the user ever sees, and only inside the
  iOS system permission dialog (iOS itself controls that dialog's chrome). All
  in-app copy is Spanish.

## Step 5 — Fill in the API base URL

1. After `sam deploy`, copy the API Gateway base URL from the deploy output
   (e.g. `https://abc123xyz.execute-api.us-west-2.amazonaws.com`).
2. Open `Configuration.plist` and replace the `API_BASE_URL` value
   `REPLACE_WITH_SAM_DEPLOY_OUTPUT` with that URL. No trailing slash.
3. Until this is set, the app runs but shows a clear "not connected" notice on
   the splash screen — it will not crash.

## Step 6 — Run on a physical iPhone

**The camera does not work in the iOS Simulator.** Capture, the redaction
animation, the scan, and the voice mic must all be tested on a real device.

1. Connect an iPhone (iOS 17+) via USB.
2. Select it as the run destination.
3. Set a **Development Team** under Signing & Capabilities (free personal team
   is fine for the hackathon).
4. Build & Run (⌘R). Approve the developer certificate on the phone if asked
   (Settings ▸ General ▸ VPN & Device Management).

The Simulator is still useful for layout, VoiceOver, and Dynamic Type checks —
just use the photo-library fallback instead of the camera there.

## Step 7 — Add the demo document (the on-stage safety net)

`SplashView` has a small **"Usar documento de demostración"** button. It
bypasses the camera and runs the bundled synthetic NTA through the exact same
`/scan` pipeline. **This is the demo safety net** — if the camera misbehaves on
stage, this button keeps the demo running.

To wire it up:

1. Take the synthetic NTA test photo (`docs/synthetic-docs/NTA_demo.jpg`, per
   `docs/synthetic-docs/NTA_demo.md`).
2. Add it to the Xcode project as an image named **`NTA_demo`**:
   - **Easiest:** open `Assets.xcassets` → drag the JPEG in → confirm the image
     set is named exactly `NTA_demo`. **OR**
   - Add the loose file `NTA_demo.jpg` to the target (Target Membership ✅).
3. `UIImage(named: "NTA_demo")` resolves either way. The asset name constant
   lives in `AppState.demoDocumentAssetName` — change it there if you rename.
4. Until the image is added, the button shows a calm "no disponible" alert
   instead of crashing — so the app is safe to ship even before the asset
   lands.

---

## Verifying the model ↔ contract binding (dry-decode)

`Sources/Services/SampleResponses.swift` (DEBUG-only) carries one JSON fixture
per response shape and an `APIDecodeCheck.run()` self-check. From a debug
build, call `APIDecodeCheck.run()` (a temporary button, or `e APIDecodeCheck.run()`
in lldb) — the console prints ✅ / ❌ per shape. All ✅ means `Models/` matches
`docs/API_CONTRACT.md`.

---

## Accessibility verification checklist (do before the demo)

The customer is grandma (TENETS.md §5). Verify on a real device:

- [ ] **VoiceOver walkthrough** — every screen: Splash → Camera → Redaction →
      Results → Ask → Refusal log → Packet → Legal help. Every control has a
      label; the refusal counter announces its count; the redaction animation
      posts its completion announcement.
- [ ] **Dynamic Type** — set the largest accessibility text size
      (Settings ▸ Accessibility ▸ Display & Text Size ▸ Larger Text). No card
      clips text; buttons stay tappable.
- [ ] **Reduce Motion** — the redaction animation still completes (no slide,
      but the pedagogical timing is preserved).
- [ ] **Touch targets** — all primary buttons are ≥ 56pt tall; the shutter and
      mic are large and centered.
- [ ] **Contrast** — colors in `DesignSystem.swift` are tuned for WCAG-AA on
      the light background; the app forces light mode for v1.
- [ ] **One-handed reachability** — primary actions sit low on the screen.

## Real-world conditions

- **Offline / network loss** — every screen has a loading, error, and retry
  state. `APIError.isRetryable` drives whether a retry button appears.
- **Permission denied** — camera-denied and mic-denied both show a calm
  explanation plus an "Open Settings" button; the camera screen still offers
  the photo-library fallback.
- **Backend not configured** — the splash screen shows a notice; no crash.
- **Ephemeral** — nothing is written to disk. Recordings are temp files,
  read once, then deleted (TENETS.md §7).

---

## Notes for reviewers

- **Models are the contract.** Everything in `Models/` matches
  `docs/API_CONTRACT.md`. snake_case ↔ camelCase is handled by the decoder's
  `.convertFromSnakeCase` strategy in `CartaClaraAPI`.
- **No hardcoded Spanish *content*.** Every document summary, section
  explanation, refusal message, scam description, and packet field is read
  straight from an API response. The one exception — static UI chrome (button
  labels, screen titles) — is centralized in `Components/UIText.swift`, with a
  full explanation of the scope decision at the top of that file.
- **Synthetic data only.** The `DemoBadge` component renders whenever the
  backend flags a demo document (TENETS.md §6).
