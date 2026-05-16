//
//  Refusal.swift
//  Carta Clara
//
//  Codable models for GET /refusal-log.
//
//  The refusal counter is part of the trust story (TENETS.md §1, §2): every
//  refusal is visible and logged. The log records PII-redacted refusal events
//  and session metadata only — never document content.
//
//  SOURCE OF TRUTH: docs/API_CONTRACT.md.
//

import Foundation

/// Response of `GET /refusal-log?session_id=...`.
struct RefusalLog: Codable {
    let sessionId: String
    let count: Int
    let refusals: [RefusalEntry]

    /// Empty log for the initial state before the first poll.
    static func empty(sessionId: String) -> RefusalLog {
        RefusalLog(sessionId: sessionId, count: 0, refusals: [])
    }
}

/// One logged refusal event. Limited to the 20 most recent, newest first.
struct RefusalEntry: Codable, Identifiable {
    let ts: String
    let reason: String
    let topicLabelEs: String

    /// Composite id — the contract has no explicit id field.
    var id: String { ts + "|" + reason }
}
