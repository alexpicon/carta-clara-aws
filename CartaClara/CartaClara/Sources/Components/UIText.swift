//
//  UIText.swift
//  Carta Clara
//
//  Centralized UI CHROME strings (button labels, screen titles, VoiceOver
//  hints, status messages).
//
//  ──────────────────────────────────────────────────────────────────────
//  BILINGUAL: every visible string ships in English AND Spanish. The active
//  language is switched at runtime via `UIText.currentLanguage`, which
//  AppState sets in its `selectedLanguage` didSet. Views continue to call
//  `UIText.foo` exactly as before — the active-language lookup happens
//  inside the computed property. SwiftUI re-renders when AppState publishes
//  the selectedLanguage change, so post-language-picker screens flip
//  immediately.
//
//  Splash and the language picker itself render in English by default,
//  since the user hasn't made a choice yet. From the picker onward
//  (camera tips, camera, redaction animation, results, ask chat, packet,
//  legal help), every screen respects the chosen language. Going back
//  and re-picking flips everything again.
//  ──────────────────────────────────────────────────────────────────────
//

import Foundation

/// UI chrome strings. Access via the static interface — `UIText.appName`,
/// `UIText.summaryCardTitle`, etc. The active language is set by AppState.
enum UIText {

    /// Active UI language. Set by AppState's `selectedLanguage` didSet.
    /// Defaults to English so the splash + language-picker screens render
    /// before the user has made a choice.
    static var currentLanguage: AppLanguage = .english

    /// The active string bundle. Switches based on `currentLanguage`.
    private static var current: UITextStrings {
        currentLanguage == .spanish ? .spanish : .english
    }

    // MARK: Brand
    static var appName: String { current.appName }
    static var tagline: String { current.tagline }

    // MARK: Splash
    static var getStarted: String { current.getStarted }
    static var tryDemoButton: String { current.tryDemoButton }
    static var demoDocMissingTitle: String { current.demoDocMissingTitle }
    static var demoDocMissingBody: String { current.demoDocMissingBody }
    static var disclaimerButton: String { current.disclaimerButton }
    static var disclaimerTitle: String { current.disclaimerTitle }
    static var disclaimerBody: String { current.disclaimerBody }
    static var disclaimerClose: String { current.disclaimerClose }

    // MARK: Camera
    static var cameraTitle: String { current.cameraTitle }
    static var cameraHint: String { current.cameraHint }
    static var captureButton: String { current.captureButton }
    static var captureA11y: String { current.captureA11y }
    static var captureA11yHint: String { current.captureA11yHint }
    static var pickFromLibrary: String { current.pickFromLibrary }
    static var cameraDeniedTitle: String { current.cameraDeniedTitle }
    static var cameraDeniedBody: String { current.cameraDeniedBody }
    static var openSettings: String { current.openSettings }
    static var retake: String { current.retake }
    static var usePhoto: String { current.usePhoto }
    static var cameraPreviewA11y: String { current.cameraPreviewA11y }
    static var libraryHint: String { current.libraryHint }
    static var pickerFailedTitle: String { current.pickerFailedTitle }
    static var confirmPhotoA11y: String { current.confirmPhotoA11y }
    static var confirmReadabilityHint: String { current.confirmReadabilityHint }

    // MARK: Camera tips
    static var cameraTipsTitle: String { current.cameraTipsTitle }
    static var cameraTipsHeading: String { current.cameraTipsHeading }
    static var cameraTipsSubheading: String { current.cameraTipsSubheading }
    static var cameraTipsContinue: String { current.cameraTipsContinue }
    static var cameraTipLightTitle: String { current.cameraTipLightTitle }
    static var cameraTipLightBody: String { current.cameraTipLightBody }
    static var cameraTipFrameTitle: String { current.cameraTipFrameTitle }
    static var cameraTipFrameBody: String { current.cameraTipFrameBody }
    static var cameraTipSteadyTitle: String { current.cameraTipSteadyTitle }
    static var cameraTipSteadyBody: String { current.cameraTipSteadyBody }
    static var cameraTipBackgroundTitle: String { current.cameraTipBackgroundTitle }
    static var cameraTipBackgroundBody: String { current.cameraTipBackgroundBody }

    // MARK: Redaction animation
    static var redactionTitle: String { current.redactionTitle }
    static var redactionCaption: String { current.redactionCaption }
    static var redactionDone: String { current.redactionDone }
    /// Honest privacy line shown as a banner at the top of the results
    /// screen — what we actually do (no account, no persistent storage,
    /// 1h TTL) rather than implying full PII filtering.
    static var resultsPrivacyBanner: String { current.resultsPrivacyBanner }
    static var processing: String { current.processing }
    static var redactionA11yAnnouncement: String { current.redactionA11yAnnouncement }
    static var redactionInProgressA11y: String { current.redactionInProgressA11y }
    static var redactionCompleteA11y: String { current.redactionCompleteA11y }
    static var redactionFields: [String] { current.redactionFields }
    static var redactedTag: String { current.redactedTag }

    // MARK: Results
    static var resultsTitle: String { current.resultsTitle }
    static var readingLevelLabel: String { current.readingLevelLabel }
    static var readingLevelBeginner: String { current.readingLevelBeginner }
    static var readingLevelIntermediate: String { current.readingLevelIntermediate }
    static var readingLevelFull: String { current.readingLevelFull }
    static var askButton: String { current.askButton }
    static var helpRespondButton: String { current.helpRespondButton }
    static var legalHelpButton: String { current.legalHelpButton }
    static var playSummary: String { current.playSummary }
    static var pauseSummary: String { current.pauseSummary }
    static var sectionExpand: String { current.sectionExpand }
    static var sectionCollapse: String { current.sectionCollapse }
    static var sectionExpandedA11y: String { current.sectionExpandedA11y }
    static var sectionCollapsedA11y: String { current.sectionCollapsedA11y }
    static var citationsLabel: String { current.citationsLabel }
    static var demoBadge: String { current.demoBadge }
    static var demoDocumentA11y: String { current.demoDocumentA11y }
    static var summaryCardTitle: String { current.summaryCardTitle }
    static var urgencyCardTitle: String { current.urgencyCardTitle }
    static var summaryA11yPrefix: String { current.summaryA11yPrefix }
    static var refusedScanTitle: String { current.refusedScanTitle }

    // MARK: Court brief card
    static var courtBriefTitle: String { current.courtBriefTitle }
    static var courtWhatToExpect: String { current.courtWhatToExpect }
    static var courtWhatToBring: String { current.courtWhatToBring }
    static var courtWhatNotToBring: String { current.courtWhatNotToBring }
    static var courtDressCode: String { current.courtDressCode }
    static var courtCallA11yPrefix: String { current.courtCallA11yPrefix }

    // MARK: Scam red flag card
    static var scamCardTitleAlert: String { current.scamCardTitleAlert }
    static var scamCardTitleSafe: String { current.scamCardTitleSafe }

    // MARK: Questions card
    static var questionsCardTitle: String { current.questionsCardTitle }
    static var questionsCardBody: String { current.questionsCardBody }
    static var questionsCardCTA: String { current.questionsCardCTA }

    // MARK: Ask / chat
    static var askTitle: String { current.askTitle }
    static var askPlaceholder: String { current.askPlaceholder }
    static var micButton: String { current.micButton }
    static var micRecording: String { current.micRecording }
    static var micA11y: String { current.micA11y }
    static var micA11yHint: String { current.micA11yHint }
    static var sendButton: String { current.sendButton }
    static var askEmptyState: String { current.askEmptyState }
    static var askThinking: String { current.askThinking }
    static var askVoiceQuestion: String { current.askVoiceQuestion }
    static var askYou: String { current.askYou }
    static var askAssistant: String { current.askAssistant }
    static var micPermissionDeniedTitle: String { current.micPermissionDeniedTitle }
    static var micPermissionDeniedBody: String { current.micPermissionDeniedBody }
    static var refusalCounterA11y: String { current.refusalCounterA11y }
    static var refusalCounterA11yHint: String { current.refusalCounterA11yHint }
    static var refusalCounterEmptyA11y: String { current.refusalCounterEmptyA11y }

    // MARK: Refusal log
    static var refusalLogTitle: String { current.refusalLogTitle }
    static var refusalLogIntro: String { current.refusalLogIntro }
    static var refusalLogEmpty: String { current.refusalLogEmpty }

    // MARK: Response packet
    static var packetTitle: String { current.packetTitle }
    static var packetGenerating: String { current.packetGenerating }
    static var packetShare: String { current.packetShare }
    static var packetShareA11y: String { current.packetShareA11y }
    static var packetShareA11yHint: String { current.packetShareA11yHint }
    static var packetPreparingShare: String { current.packetPreparingShare }

    // MARK: Legal help
    static var legalHelpTitle: String { current.legalHelpTitle }
    static var legalHelpIntro: String { current.legalHelpIntro }
    static var callButton: String { current.callButton }
    static var directionsButton: String { current.directionsButton }
    static var freeBadge: String { current.freeBadge }
    static var legalHelpVerifyNote: String { current.legalHelpVerifyNote }
    static var legalHelpHoursLabel: String { current.legalHelpHoursLabel }
    static var legalHelpLanguagesLabel: String { current.legalHelpLanguagesLabel }

    // MARK: Splash accessibility hints
    static var splashCameraHint: String { current.splashCameraHint }
    static var splashDemoHint: String { current.splashDemoHint }

    // MARK: Response packet section headers
    static var packetWhatItSays: String { current.packetWhatItSays }
    static var packetDeadline: String { current.packetDeadline }
    static var packetDocuments: String { current.packetDocuments }
    static var packetExtension: String { current.packetExtension }
    static var packetPhoneScript: String { current.packetPhoneScript }
    static var packetQuestions: String { current.packetQuestions }
    static var packetCoverSheet: String { current.packetCoverSheet }
    static var packetError: String { current.packetError }

    // MARK: Errors / empty / offline
    static var errorTitle: String { current.errorTitle }
    static var errorGeneric: String { current.errorGeneric }
    static var errorOffline: String { current.errorOffline }
    static var errorRetry: String { current.errorRetry }
    static var errorNotConfigured: String { current.errorNotConfigured }
    static var loading: String { current.loading }

    // MARK: Restart toolbar
    static var restartScan: String { current.restartScan }

    // MARK: Chat refusal label
    static var askRefusalLabel: String { current.askRefusalLabel }

    // MARK: Reading-level display helper
    static func readingLevelName(_ level: ReadingLevel) -> String {
        switch level {
        case .intermediate: return readingLevelIntermediate
        case .full: return readingLevelFull
        }
    }

    /// Localized caption under the refusal-log header — "1 question
    /// refused this session" vs "2 questions refused this session".
    static func refusalCountCaption(_ count: Int) -> String {
        if currentLanguage == .spanish {
            return count == 1
                ? "pregunta rechazada en esta sesión"
                : "preguntas rechazadas en esta sesión"
        }
        return count == 1
            ? "question refused this session"
            : "questions refused this session"
    }
}

// MARK: - String bundle

/// One language's worth of UI chrome strings. There are exactly two
/// instances: `.english` (default) and `.spanish`.
struct UITextStrings {
    let appName: String
    let tagline: String

    let getStarted: String
    let tryDemoButton: String
    let demoDocMissingTitle: String
    let demoDocMissingBody: String
    let disclaimerButton: String
    let disclaimerTitle: String
    let disclaimerBody: String
    let disclaimerClose: String

    let cameraTitle: String
    let cameraHint: String
    let captureButton: String
    let captureA11y: String
    let captureA11yHint: String
    let pickFromLibrary: String
    let cameraDeniedTitle: String
    let cameraDeniedBody: String
    let openSettings: String
    let retake: String
    let usePhoto: String
    let cameraPreviewA11y: String
    let libraryHint: String
    let pickerFailedTitle: String
    let confirmPhotoA11y: String
    let confirmReadabilityHint: String

    // Camera tips
    let cameraTipsTitle: String
    let cameraTipsHeading: String
    let cameraTipsSubheading: String
    let cameraTipsContinue: String
    let cameraTipLightTitle: String
    let cameraTipLightBody: String
    let cameraTipFrameTitle: String
    let cameraTipFrameBody: String
    let cameraTipSteadyTitle: String
    let cameraTipSteadyBody: String
    let cameraTipBackgroundTitle: String
    let cameraTipBackgroundBody: String

    let redactionTitle: String
    let redactionCaption: String
    let redactionDone: String
    let resultsPrivacyBanner: String
    let processing: String
    let redactionA11yAnnouncement: String
    let redactionInProgressA11y: String
    let redactionCompleteA11y: String
    let redactionFields: [String]
    let redactedTag: String

    let resultsTitle: String
    let readingLevelLabel: String
    let readingLevelBeginner: String
    let readingLevelIntermediate: String
    let readingLevelFull: String
    let askButton: String
    let helpRespondButton: String
    let legalHelpButton: String
    let playSummary: String
    let pauseSummary: String
    let sectionExpand: String
    let sectionCollapse: String
    let sectionExpandedA11y: String
    let sectionCollapsedA11y: String
    let citationsLabel: String
    let demoBadge: String
    let demoDocumentA11y: String
    let summaryCardTitle: String
    let urgencyCardTitle: String
    let summaryA11yPrefix: String
    let refusedScanTitle: String

    let courtBriefTitle: String
    let courtWhatToExpect: String
    let courtWhatToBring: String
    let courtWhatNotToBring: String
    let courtDressCode: String
    let courtCallA11yPrefix: String

    let scamCardTitleAlert: String
    let scamCardTitleSafe: String

    let questionsCardTitle: String
    let questionsCardBody: String
    let questionsCardCTA: String

    let askTitle: String
    let askPlaceholder: String
    let micButton: String
    let micRecording: String
    let micA11y: String
    let micA11yHint: String
    let sendButton: String
    let askEmptyState: String
    let askThinking: String
    let askVoiceQuestion: String
    let askYou: String
    let askAssistant: String
    let micPermissionDeniedTitle: String
    let micPermissionDeniedBody: String
    let refusalCounterA11y: String
    let refusalCounterA11yHint: String
    let refusalCounterEmptyA11y: String

    let refusalLogTitle: String
    let refusalLogIntro: String
    let refusalLogEmpty: String

    let packetTitle: String
    let packetGenerating: String
    let packetShare: String
    let packetShareA11y: String
    let packetShareA11yHint: String
    let packetPreparingShare: String

    let legalHelpTitle: String
    let legalHelpIntro: String
    let callButton: String
    let directionsButton: String
    let freeBadge: String
    let legalHelpVerifyNote: String
    let legalHelpHoursLabel: String
    let legalHelpLanguagesLabel: String

    let splashCameraHint: String
    let splashDemoHint: String

    let packetWhatItSays: String
    let packetDeadline: String
    let packetDocuments: String
    let packetExtension: String
    let packetPhoneScript: String
    let packetQuestions: String
    let packetCoverSheet: String
    let packetError: String

    let errorTitle: String
    let errorGeneric: String
    let errorOffline: String
    let errorRetry: String
    let errorNotConfigured: String
    let loading: String

    let restartScan: String
    let askRefusalLabel: String
}

// MARK: - English (default)

extension UITextStrings {
    static let english = UITextStrings(
        appName: "Carta Clara",
        tagline: "Understand your letter. Calmly.",

        getStarted: "Start scanning",
        tryDemoButton: "Use the demo document",
        demoDocMissingTitle: "Demo document not available",
        demoDocMissingBody: "The demo document isn't bundled with the app yet. Use the camera or pick a saved photo.",
        disclaimerButton: "What this app does not do",
        disclaimerTitle: "Information, not legal advice",
        disclaimerBody: """
        Carta Clara explains what a document says, what is urgent, and what \
        questions to ask a lawyer.

        Carta Clara does NOT give legal advice. It does not draft responses to \
        USCIS, the court, or ICE. It does not tell you what to say, what to \
        admit, or whether you qualify for anything.

        When a question needs a lawyer, the app stops and connects you with \
        free legal help.
        """,
        disclaimerClose: "I understand",

        cameraTitle: "Take a photo of the document",
        cameraHint: "Center the document in the frame and hold steady.",
        captureButton: "Take photo",
        captureA11y: "Take a photo of the document",
        captureA11yHint: "Activates the camera and captures the letter.",
        pickFromLibrary: "Pick a saved photo",
        cameraDeniedTitle: "The camera is off",
        cameraDeniedBody: "To take a photo, turn on camera permission in Settings. You can also pick a saved photo.",
        openSettings: "Open Settings",
        retake: "Take another",
        usePhoto: "Use this photo",
        cameraPreviewA11y: "Camera preview",
        libraryHint: "Pick a photo you already have saved.",
        pickerFailedTitle: "We couldn't open that photo",
        confirmPhotoA11y: "Photo of the document you took",
        confirmReadabilityHint: "Can you read the text? If you can read it, the app can read it too.",

        cameraTipsTitle: "Before you scan",
        cameraTipsHeading: "Tips for a clear scan",
        cameraTipsSubheading: "A few seconds of setup makes the result much better.",
        cameraTipsContinue: "Open the camera",
        cameraTipLightTitle: "Good light",
        cameraTipLightBody: "Stand near a window or turn on a lamp. Avoid shadows on the document.",
        cameraTipFrameTitle: "Fit the whole page",
        cameraTipFrameBody: "Center the document inside the corner marks. Edges should be visible.",
        cameraTipSteadyTitle: "Hold steady",
        cameraTipSteadyBody: "Take a breath and keep the phone still for a second before tapping.",
        cameraTipBackgroundTitle: "Avoid glare",
        cameraTipBackgroundBody: "If the page is shiny under overhead light, tilt it slightly so reflections don't wash out the words.",

        redactionTitle: "Protecting your information",
        redactionCaption: "We mask your data before sending anything.",
        redactionDone: "Your information is protected.",
        resultsPrivacyBanner: "Your photo will be deleted in 1 hour. No account, no tracking.",
        processing: "Reading the document…",
        redactionA11yAnnouncement: "Your personal information was masked. The document is now protected.",
        redactionInProgressA11y: "Masking the document's personal information.",
        redactionCompleteA11y: "Document with personal information masked.",
        redactionFields: ["Name", "A-Number", "Address", "Date of birth", "Case number"],
        redactedTag: "PROTECTED",

        resultsTitle: "Your document",
        readingLevelLabel: "Reading level",
        readingLevelBeginner: "Plain",
        readingLevelIntermediate: "Plain",
        readingLevelFull: "Detailed",
        askButton: "Ask about this document",
        helpRespondButton: "Help me respond",
        legalHelpButton: "Find free legal help",
        playSummary: "Listen to the summary",
        pauseSummary: "Pause the summary",
        sectionExpand: "Show more",
        sectionCollapse: "Show less",
        sectionExpandedA11y: "Expanded",
        sectionCollapsedA11y: "Collapsed",
        citationsLabel: "Sources",
        demoBadge: "DEMO DOCUMENT",
        demoDocumentA11y: "Demo document. Not a real case.",
        summaryCardTitle: "Summary",
        urgencyCardTitle: "Important date",
        summaryA11yPrefix: "Summary",
        refusedScanTitle: "We can't analyze this document",

        courtBriefTitle: "About the court",
        courtWhatToExpect: "What to expect",
        courtWhatToBring: "What to bring",
        courtWhatNotToBring: "What NOT to bring",
        courtDressCode: "How to dress",
        courtCallA11yPrefix: "Call the court:",

        scamCardTitleAlert: "Signs to be careful about",
        scamCardTitleSafe: "Scam check",

        questionsCardTitle: "Questions for your lawyer",
        questionsCardBody: "Prepare the right questions before your appointment with a lawyer. We include them in your preparation packet.",
        questionsCardCTA: "Create my packet",

        askTitle: "Ask",
        askPlaceholder: "Type your question…",
        micButton: "Press and hold to speak",
        micRecording: "Recording… release to send",
        micA11y: "Voice button",
        micA11yHint: "Press and hold to record your question. Release to send.",
        sendButton: "Send",
        askEmptyState: "Ask a question about your document. You can speak or type.",
        askThinking: "Thinking…",
        askVoiceQuestion: "Voice question",
        askYou: "You",
        askAssistant: "Carta Clara",
        micPermissionDeniedTitle: "The microphone is off",
        micPermissionDeniedBody: "To ask with your voice, turn on microphone permission in Settings. You can also type your question.",
        refusalCounterA11y: "Counter of unanswered questions",
        refusalCounterA11yHint: "Tap to see which questions the app does not answer, and why.",
        refusalCounterEmptyA11y: "No questions refused yet.",

        refusalLogTitle: "What this app does not answer",
        refusalLogIntro: "When a question needs a lawyer, the app does not answer it. That's by design.",
        refusalLogEmpty: "None yet. When the app stops on a legal question, it will appear here.",

        packetTitle: "Preparation packet",
        packetGenerating: "Preparing your packet…",
        packetShare: "Share or print",
        packetShareA11y: "Share or print the preparation packet",
        packetShareA11yHint: "Share or print this packet for your legal-help appointment.",
        packetPreparingShare: "Preparing the document…",

        legalHelpTitle: "Free legal help",
        legalHelpIntro: "These organizations offer free consultations. Call or visit.",
        callButton: "Call",
        directionsButton: "Directions",
        freeBadge: "FREE",
        legalHelpVerifyNote: "Confirm hours and address by calling before going. Contact info may change.",
        legalHelpHoursLabel: "Hours",
        legalHelpLanguagesLabel: "Languages",

        splashCameraHint: "Opens the camera to photograph your document.",
        splashDemoHint: "Loads a sample document without using the camera.",

        packetWhatItSays: "What this document says",
        packetDeadline: "Your deadline",
        packetDocuments: "Documents to gather",
        packetExtension: "Request for more time",
        packetPhoneScript: "What to say when you call",
        packetQuestions: "Questions for your lawyer",
        packetCoverSheet: "Cover sheet",
        packetError: "We couldn't create the packet. Please try again.",

        errorTitle: "Something went wrong",
        errorGeneric: "We couldn't finish. Check your connection and try again.",
        errorOffline: "No internet connection. Connect and try again.",
        errorRetry: "Try again",
        errorNotConfigured: "The app isn't connected to the server yet. API_BASE_URL is missing in Configuration.plist.",
        loading: "Loading…",

        restartScan: "Scan another document",
        askRefusalLabel: "This needs a lawyer"
    )
}

// MARK: - Spanish

extension UITextStrings {
    static let spanish = UITextStrings(
        appName: "Carta Clara",
        tagline: "Entiende tu carta. Con calma.",

        getStarted: "Empezar a escanear",
        tryDemoButton: "Usar documento de demostración",
        demoDocMissingTitle: "Documento de demostración no disponible",
        demoDocMissingBody: "El documento de demostración todavía no está incluido en la app. Usa la cámara o elige una foto guardada.",
        disclaimerButton: "Lo que esta app no hace",
        disclaimerTitle: "Información, no consejo legal",
        disclaimerBody: """
        Carta Clara explica lo que dice un documento, qué es urgente y qué \
        preguntas hacerle a un abogado.

        Carta Clara NO da consejo legal. No le responde a USCIS, a la corte ni \
        a ICE. No te dice qué decir, qué admitir ni si calificas para algo.

        Cuando una pregunta necesita un abogado, la app se detiene y te \
        conecta con ayuda legal gratis.
        """,
        disclaimerClose: "Entiendo",

        cameraTitle: "Toma una foto del documento",
        cameraHint: "Centra el documento en el marco y mantén la cámara firme.",
        captureButton: "Tomar foto",
        captureA11y: "Tomar foto del documento",
        captureA11yHint: "Activa la cámara y captura la carta.",
        pickFromLibrary: "Elegir una foto guardada",
        cameraDeniedTitle: "La cámara está apagada",
        cameraDeniedBody: "Para tomar una foto, activa el permiso de cámara en Ajustes. También puedes elegir una foto guardada.",
        openSettings: "Abrir Ajustes",
        retake: "Tomar otra",
        usePhoto: "Usar esta foto",
        cameraPreviewA11y: "Vista de la cámara",
        libraryHint: "Elige una foto que ya tienes guardada.",
        pickerFailedTitle: "No pudimos abrir esa foto",
        confirmPhotoA11y: "Foto del documento que tomaste",
        confirmReadabilityHint: "¿Puedes leer el texto? Si tú puedes leerlo, la app también puede.",

        cameraTipsTitle: "Antes de escanear",
        cameraTipsHeading: "Consejos para una foto clara",
        cameraTipsSubheading: "Unos segundos de preparación mejoran mucho el resultado.",
        cameraTipsContinue: "Abrir la cámara",
        cameraTipLightTitle: "Buena luz",
        cameraTipLightBody: "Acércate a una ventana o enciende una lámpara. Evita sombras sobre el documento.",
        cameraTipFrameTitle: "Encuadra toda la página",
        cameraTipFrameBody: "Centra el documento dentro de las esquinas. Los bordes deben verse.",
        cameraTipSteadyTitle: "Mantén firme",
        cameraTipSteadyBody: "Respira y mantén el teléfono quieto por un segundo antes de tomar la foto.",
        cameraTipBackgroundTitle: "Evita los reflejos",
        cameraTipBackgroundBody: "Si la página brilla con la luz de arriba, inclínala un poco para que los reflejos no borren las letras.",

        redactionTitle: "Protegiendo tu información",
        redactionCaption: "Tapamos tus datos antes de enviar nada.",
        redactionDone: "Tu información está protegida.",
        resultsPrivacyBanner: "Tu foto se elimina en 1 hora. Sin cuenta, sin rastreo.",
        processing: "Leyendo el documento…",
        redactionA11yAnnouncement: "Tu información personal fue tapada. El documento ya está protegido.",
        redactionInProgressA11y: "Tapando la información personal del documento.",
        redactionCompleteA11y: "Documento con la información personal tapada.",
        redactionFields: ["Nombre", "Número A", "Dirección", "Fecha de nacimiento", "Número de caso"],
        redactedTag: "PROTEGIDO",

        resultsTitle: "Tu documento",
        readingLevelLabel: "Nivel de lectura",
        readingLevelBeginner: "Sencillo",
        readingLevelIntermediate: "Sencillo",
        readingLevelFull: "Detallado",
        askButton: "Preguntar sobre este documento",
        helpRespondButton: "Ayúdame a responder",
        legalHelpButton: "Buscar ayuda legal gratis",
        playSummary: "Escuchar el resumen",
        pauseSummary: "Pausar el resumen",
        sectionExpand: "Ver más",
        sectionCollapse: "Ver menos",
        sectionExpandedA11y: "Desplegado",
        sectionCollapsedA11y: "Contraído",
        citationsLabel: "Fuentes",
        demoBadge: "DOCUMENTO DE DEMOSTRACIÓN",
        demoDocumentA11y: "Documento de demostración. No es un caso real.",
        summaryCardTitle: "Resumen",
        urgencyCardTitle: "Fecha importante",
        summaryA11yPrefix: "Resumen",
        refusedScanTitle: "No podemos analizar este documento",

        courtBriefTitle: "Sobre la corte",
        courtWhatToExpect: "Qué esperar",
        courtWhatToBring: "Qué llevar",
        courtWhatNotToBring: "Qué NO llevar",
        courtDressCode: "Cómo vestir",
        courtCallA11yPrefix: "Llamar a la corte:",

        scamCardTitleAlert: "Señales para tener cuidado",
        scamCardTitleSafe: "Revisión de estafas",

        questionsCardTitle: "Preguntas para tu abogado",
        questionsCardBody: "Prepara las preguntas correctas antes de tu cita con un abogado. Las incluimos en tu paquete de preparación.",
        questionsCardCTA: "Crear mi paquete",

        askTitle: "Preguntar",
        askPlaceholder: "Escribe tu pregunta…",
        micButton: "Mantén presionado para hablar",
        micRecording: "Grabando… suelta para enviar",
        micA11y: "Botón de voz",
        micA11yHint: "Mantén presionado para grabar tu pregunta. Suelta para enviarla.",
        sendButton: "Enviar",
        askEmptyState: "Haz una pregunta sobre tu documento. Puedes hablar o escribir.",
        askThinking: "Pensando…",
        askVoiceQuestion: "Pregunta por voz",
        askYou: "Tú",
        askAssistant: "Carta Clara",
        micPermissionDeniedTitle: "El micrófono está apagado",
        micPermissionDeniedBody: "Para preguntar con tu voz, activa el permiso del micrófono en Ajustes. También puedes escribir tu pregunta.",
        refusalCounterA11y: "Contador de respuestas no dadas",
        refusalCounterA11yHint: "Toca para ver qué preguntas la app no contesta y por qué.",
        refusalCounterEmptyA11y: "Ninguna pregunta rechazada todavía.",

        refusalLogTitle: "Lo que esta app no contesta",
        refusalLogIntro: "Cuando una pregunta necesita un abogado, la app no la contesta. Esa es la idea.",
        refusalLogEmpty: "Ninguna todavía. Cuando la app se detenga ante una pregunta legal, aparecerá aquí.",

        packetTitle: "Paquete de preparación",
        packetGenerating: "Preparando tu paquete…",
        packetShare: "Compartir o imprimir",
        packetShareA11y: "Compartir o imprimir el paquete de preparación",
        packetShareA11yHint: "Comparte o imprime este paquete para tu cita de ayuda legal.",
        packetPreparingShare: "Preparando el documento…",

        legalHelpTitle: "Ayuda legal gratis",
        legalHelpIntro: "Estas organizaciones ofrecen consultas gratis. Llama o visita.",
        callButton: "Llamar",
        directionsButton: "Cómo llegar",
        freeBadge: "GRATIS",
        legalHelpVerifyNote: "Confirma los horarios y la dirección llamando antes de ir. La información de contacto puede cambiar.",
        legalHelpHoursLabel: "Horario",
        legalHelpLanguagesLabel: "Idiomas",

        splashCameraHint: "Abre la cámara para fotografiar tu documento.",
        splashDemoHint: "Carga un documento de ejemplo sin usar la cámara.",

        packetWhatItSays: "Qué dice este documento",
        packetDeadline: "Tu fecha límite",
        packetDocuments: "Documentos para reunir",
        packetExtension: "Solicitud para pedir más tiempo",
        packetPhoneScript: "Qué decir cuando llames",
        packetQuestions: "Preguntas para tu abogado",
        packetCoverSheet: "Hoja de presentación",
        packetError: "No pudimos crear el paquete. Inténtalo otra vez.",

        errorTitle: "Algo salió mal",
        errorGeneric: "No pudimos terminar. Revisa tu conexión e inténtalo otra vez.",
        errorOffline: "No hay conexión a internet. Conéctate e inténtalo otra vez.",
        errorRetry: "Intentar otra vez",
        errorNotConfigured: "La app aún no está conectada al servidor. Falta el API_BASE_URL en Configuration.plist.",
        loading: "Cargando…",

        restartScan: "Escanear otro documento",
        askRefusalLabel: "Esto necesita un abogado"
    )
}
