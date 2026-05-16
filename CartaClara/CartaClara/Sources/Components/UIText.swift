//
//  UIText.swift
//  Carta Clara
//
//  Centralized UI CHROME strings (button labels, screen titles, VoiceOver
//  hints, status messages).
//
//  ──────────────────────────────────────────────────────────────────────
//  LANGUAGE: English by default during the team-development phase.
//  Spanish-first is the production target (TENETS.md §9, currently amended).
//  Document CONTENT (summaries, sections, refusal text, scam descriptions,
//  packet copy) is still sourced from the backend response — this file is
//  CHROME only. When we flip back to Spanish-first, this is the single file
//  to retranslate, and the views switch from `summaryEn` back to `summaryEs`.
//  ──────────────────────────────────────────────────────────────────────
//

import Foundation

/// All static UI chrome strings, in English by default.
enum UIText {

    // MARK: Brand
    static let appName = "Carta Clara"
    static let tagline = "Understand your letter. Calmly."

    // MARK: Splash
    static let getStarted = "Get started"
    static let tryDemoButton = "Use the demo document"
    static let demoDocMissingTitle = "Demo document not available"
    static let demoDocMissingBody = "The demo document isn't bundled with the app yet. Use the camera or pick a saved photo."
    static let disclaimerButton = "What this app does not do"
    static let disclaimerTitle = "Information, not legal advice"
    /// The disclaimer body. Fixed, non-legal-advice product statement —
    /// mirrors TENETS.md §3 and the Press Release in intent.
    static let disclaimerBody = """
    Carta Clara explains what a document says, what is urgent, and what \
    questions to ask a lawyer.

    Carta Clara does NOT give legal advice. It does not draft responses to \
    USCIS, the court, or ICE. It does not tell you what to say, what to \
    admit, or whether you qualify for anything.

    When a question needs a lawyer, the app stops and connects you with \
    free legal help.
    """
    static let disclaimerClose = "I understand"

    // MARK: Camera
    static let cameraTitle = "Take a photo of the document"
    static let cameraHint = "Place the letter on a table with good light."
    static let captureButton = "Take photo"
    static let captureA11y = "Take a photo of the document"
    static let captureA11yHint = "Activates the camera and captures the letter."
    static let pickFromLibrary = "Pick a saved photo"
    static let cameraDeniedTitle = "The camera is off"
    static let cameraDeniedBody = "To take a photo, turn on camera permission in Settings. You can also pick a saved photo."
    static let openSettings = "Open Settings"
    static let retake = "Take another"
    static let usePhoto = "Use this photo"
    static let cameraPreviewA11y = "Camera preview"
    static let libraryHint = "Pick a photo you already have saved."
    static let pickerFailedTitle = "We couldn't open that photo"
    static let confirmPhotoA11y = "Photo of the document you took"

    // MARK: Redaction animation
    static let redactionTitle = "Protecting your information"
    static let redactionCaption = "We mask your data before sending anything."
    static let redactionDone = "Your information is protected."
    static let processing = "Reading the document…"
    /// VoiceOver announcement posted when masking finishes.
    static let redactionA11yAnnouncement = "Your personal information was masked. The document is now protected."
    static let redactionInProgressA11y = "Masking the document's personal information."
    static let redactionCompleteA11y = "Document with personal information masked."
    /// PII categories shown being masked. Field-CATEGORY labels (UI chrome),
    /// not values — no synthetic or real PII is ever displayed.
    static let redactionFields: [String] = [
        "Name", "A-Number", "Address", "Date of birth", "Case number"
    ]
    static let redactedTag = "PROTECTED"

    // MARK: Results
    static let resultsTitle = "Your document"
    static let readingLevelLabel = "Reading level"
    static let readingLevelBeginner = "Simple"
    static let readingLevelIntermediate = "Normal"
    static let readingLevelFull = "Full"
    static let askButton = "Ask about this document"
    static let helpRespondButton = "Help me respond"
    static let legalHelpButton = "Find free legal help"
    static let playSummary = "Listen to the summary"
    static let pauseSummary = "Pause the summary"
    static let sectionExpand = "Show more"
    static let sectionCollapse = "Show less"
    static let sectionExpandedA11y = "Expanded"
    static let sectionCollapsedA11y = "Collapsed"
    static let citationsLabel = "Sources"
    static let demoBadge = "DEMO DOCUMENT"
    static let demoDocumentA11y = "Demo document. Not a real case."
    static let summaryCardTitle = "Summary"
    static let summaryA11yPrefix = "Summary"
    static let refusedScanTitle = "We can't analyze this document"

    // MARK: Court brief card
    static let courtBriefTitle = "About the court"
    static let courtWhatToExpect = "What to expect"
    static let courtWhatToBring = "What to bring"
    static let courtWhatNotToBring = "What NOT to bring"
    static let courtDressCode = "How to dress"
    static let courtCallA11yPrefix = "Call the court:"

    // MARK: Scam red flag card
    static let scamCardTitleAlert = "Signs to be careful about"
    static let scamCardTitleSafe = "Scam check"

    // MARK: Questions card (results)
    // The /scan contract carries no "questions" array — the questions for
    // the lawyer live in the /scan/packet response. This card routes to the
    // Response Preparation Packet.
    static let questionsCardTitle = "Questions for your lawyer"
    static let questionsCardBody = "Prepare the right questions before your appointment with a lawyer. We include them in your preparation packet."
    static let questionsCardCTA = "Create my packet"

    // MARK: Ask / chat
    static let askTitle = "Ask"
    static let askPlaceholder = "Type your question…"
    static let micButton = "Press and hold to speak"
    static let micRecording = "Recording… release to send"
    static let micA11y = "Voice button"
    static let micA11yHint = "Press and hold to record your question. Release to send."
    static let sendButton = "Send"
    static let askEmptyState = "Ask a question about your document. You can speak or type."
    static let askThinking = "Thinking…"
    static let askVoiceQuestion = "Voice question"
    static let askYou = "You"
    static let askAssistant = "Carta Clara"
    static let micPermissionDeniedTitle = "The microphone is off"
    static let micPermissionDeniedBody = "To ask with your voice, turn on microphone permission in Settings. You can also type your question."
    static let refusalCounterA11y = "Counter of unanswered questions"
    static let refusalCounterA11yHint = "Tap to see which questions the app does not answer, and why."
    static let refusalCounterEmptyA11y = "No questions refused yet."

    // MARK: Refusal log
    static let refusalLogTitle = "What this app does not answer"
    static let refusalLogIntro = "When a question needs a lawyer, the app does not answer it. That's by design."
    static let refusalLogEmpty = "None yet. When the app stops on a legal question, it will appear here."

    // MARK: Response packet
    static let packetTitle = "Preparation packet"
    static let packetGenerating = "Preparing your packet…"
    static let packetShare = "Share or print"
    static let packetShareA11y = "Share or print the preparation packet"
    static let packetShareA11yHint = "Share or print this packet for your legal-help appointment."
    static let packetPreparingShare = "Preparing the document…"

    // MARK: Legal help
    static let legalHelpTitle = "Free legal help"
    static let legalHelpIntro = "These organizations offer free consultations. Call or visit."
    static let callButton = "Call"
    static let directionsButton = "Directions"
    static let freeBadge = "FREE"
    static let legalHelpVerifyNote = "Confirm hours and address by calling before going. Contact info may change."
    static let legalHelpHoursLabel = "Hours"
    static let legalHelpLanguagesLabel = "Languages"

    // MARK: Splash accessibility hints
    static let splashCameraHint = "Opens the camera to photograph your document."
    static let splashDemoHint = "Loads a sample document without using the camera."

    // MARK: Response packet section headers (chrome — content is from the API)
    static let packetWhatItSays = "What this document says"
    static let packetDeadline = "Your deadline"
    static let packetDocuments = "Documents to gather"
    static let packetExtension = "Request for more time"
    static let packetPhoneScript = "What to say when you call"
    static let packetQuestions = "Questions for your lawyer"
    static let packetCoverSheet = "Cover sheet"
    static let packetError = "We couldn't create the packet. Please try again."

    // MARK: Errors / empty / offline
    static let errorTitle = "Something went wrong"
    static let errorGeneric = "We couldn't finish. Check your connection and try again."
    static let errorOffline = "No internet connection. Connect and try again."
    static let errorRetry = "Try again"
    static let errorNotConfigured = "The app isn't connected to the server yet. API_BASE_URL is missing in Configuration.plist."
    static let loading = "Loading…"

    // MARK: Reading-level display helper
    static func readingLevelName(_ level: ReadingLevel) -> String {
        switch level {
        case .beginner: return readingLevelBeginner
        case .intermediate: return readingLevelIntermediate
        case .full: return readingLevelFull
        }
    }
}
