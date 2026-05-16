//
//  Document.swift
//  Carta Clara
//
//  Codable models for the POST /scan and POST /ask responses.
//  Field shapes match docs/API_CONTRACT.md exactly. snake_case JSON keys are
//  mapped to camelCase Swift properties by the decoder's
//  `.convertFromSnakeCase` strategy (configured in CartaClaraAPI).
//
//  SOURCE OF TRUTH: docs/API_CONTRACT.md. If the Lambda and this file
//  disagree, the contract wins — change the code, not the contract.
//

import Foundation

// MARK: - Request parameters

/// Controls Spanish complexity. Sent as the `reading_level` request field on
/// /scan and bound to the reading-level slider in ResultsView.
enum ReadingLevel: String, Codable, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case full

    var id: String { rawValue }
}

// MARK: - POST /scan response

/// Top-level response of `POST /scan`.
///
/// Two shapes share this struct: the normal extraction result and the
/// Guardrails refusal case (`was_refused == true`). Refusal fields are
/// optional so a single decode handles both.
struct ScanResult: Codable {
    let sessionId: String
    let documentId: String?
    let extraction: Extraction?
    let summaryEn: String?
    let summaryEs: String?
    let audioUrl: String?
    let sections: [DocumentSection]?
    let urgency: Urgency?
    /// Educational Spanish scam message — present even when zero flags were
    /// detected (it explains what to watch for going forward). Maps from
    /// `scam_check_summary_es`.
    let scamCheckSummaryEs: String?
    let scamRedFlags: [ScamRedFlag]?
    let courtBrief: CourtBrief?
    let legalAidOptions: [LegalAidOption]?
    let citations: [Citation]?
    let latencyMs: Int?
    let costEstimateUsd: Double?

    // Refusal case (200 OK with was_refused == true)
    let wasRefused: Bool?
    let refusalReason: String?
    let refusalTextEs: String?

    /// True when the scan itself was refused by Guardrails.
    var isRefusal: Bool { wasRefused == true }
}

/// Structured fields extracted from the document image. All personally
/// identifying values are redacted before the model sees them — hence the
/// `*Redacted` booleans rather than the values themselves.
struct Extraction: Codable {
    let documentType: String?
    let issuingAgency: String?
    let namesRedacted: Bool?
    let aNumberRedacted: Bool?
    let addressRedacted: Bool?
    let countryOfOrigin: String?
    let countryOfCitizenship: String?
    let hearingDate: String?
    let hearingTime: String?
    let courtName: String?
    let courtAddress: String?
    let issuingOfficer: String?
    let allegedBasisSummary: String?
    let chargesCited: [String]?
    let deadlineCritical: String?
    let isDemoDocument: Bool?
    let demoWatermarkDetected: Bool?
}

/// One expandable section card. Carries both a reading-level-tuned body and a
/// full-detail body; the reading-level slider chooses which the UI shows.
struct DocumentSection: Codable, Identifiable {
    let sectionTitleEn: String
    let sectionTitleEs: String
    let sectionBodyEs: String
    let sectionBodyFullEs: String
    let citationIds: [String]?

    /// Identifiable via a computed property so it is not part of the Codable
    /// surface (the contract has no `id` field for sections).
    var id: String { sectionTitleEn }

    /// Body to display for a given reading level.
    func body(for level: ReadingLevel) -> String {
        level == .full ? sectionBodyFullEs : sectionBodyEs
    }
}

/// Deadline / urgency banner content.
struct Urgency: Codable {
    let isUrgent: Bool
    let deadlineDate: String?
    let deadlineLabelEs: String?
    let verificationNoteEs: String?
}

/// One detected scam / notario red-flag pattern. Always cited to a public
/// source — never an accusation, only "this pattern is associated with scams."
struct ScamRedFlag: Codable, Identifiable {
    let patternName: String
    let patternDescriptionEs: String
    let citationUrl: String?
    let citationSource: String?

    var id: String { patternName }
}

/// "What to expect at this courthouse" brief. Never analyzes the judge.
struct CourtBrief: Codable {
    let courtName: String
    let address: String
    let phone: String?
    let whatToExpectEs: String
    let whatToBringEs: [String]
    let whatNotToBringEs: [String]
    let dressCodeEs: String
}

/// A free legal-aid clinic the user can be routed to.
struct LegalAidOption: Codable, Identifiable {
    let name: String
    let phone: String
    let address: String
    let hours: String?
    let languages: [String]?
    let free: Bool?

    var id: String { name }
}

/// A source citation backing a grounded claim. `id` is part of the contract.
struct Citation: Codable, Identifiable {
    let id: String
    let sourceLabel: String
    let kbChunkId: String?
    let url: String?
}

// MARK: - POST /ask response

/// Top-level response of `POST /ask`. Handles both the answered case and the
/// Guardrails refusal case (`was_refused == true`).
struct AskResult: Codable {
    let sessionId: String
    let questionTranscribed: String?
    let answerEs: String?
    let answerAudioUrl: String?
    let citations: [Citation]?
    let wasRefused: Bool
    let refusalReason: String?
    let refusalTextEs: String?
    let legalAidOptions: [LegalAidOption]?
    let latencyMs: Int?
}
