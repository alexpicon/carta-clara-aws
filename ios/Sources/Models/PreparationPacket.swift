//
//  PreparationPacket.swift
//  Carta Clara
//
//  Codable models for POST /scan/packet — the Response Preparation Packet.
//
//  The packet is the artifact the user brings to a free legal-aid appointment.
//  It is NEVER a response to USCIS/EOIR/ICE/a court (TENETS.md §3, bright
//  lines). The cover sheet says so explicitly.
//
//  SOURCE OF TRUTH: docs/API_CONTRACT.md.
//

import Foundation

/// Top-level response of `POST /scan/packet`.
struct PacketResult: Codable {
    let sessionId: String
    let packet: PreparationPacket
    let legalAidOptions: [LegalAidOption]?
    /// If null, the iOS app renders the Markdown packet locally.
    let pdfUrl: String?
}

/// The preparation-packet content. All `_es` fields are Spanish copy generated
/// by the backend — never composed on-device.
struct PreparationPacket: Codable {
    let titleEs: String
    let whatThisSaysEs: String
    let yourDeadline: PacketDeadline?
    let documentsToGatherEs: [String]
    let extensionRequestTemplate: String
    let legalAidPhoneScriptEs: String
    let questionsForLawyerEs: [String]
    let coverSheetEs: String
}

/// The deadline block inside a preparation packet.
struct PacketDeadline: Codable {
    let date: String?
    let labelEs: String?
}
