//
//  SampleResponses.swift
//  Carta Clara
//
//  DEBUG-only sample API responses + a decode self-check (RIKU-18).
//
//  These JSON fixtures mirror docs/API_CONTRACT.md. They are NOT shipped UI
//  copy — they are test data that simulates the backend so the Codable models
//  in Models/ can be dry-decoded for contract drift.
//
//  HOW TO RUN THE DRY-DECODE:
//    From a debug build, call `APIDecodeCheck.run()` (e.g. from a temporary
//    button, or `(lldb) e APIDecodeCheck.run()`). Each response shape is
//    decoded with the same decoder configuration the real client uses; the
//    console prints ✅ / ❌ per shape. All ✅ means the models match the
//    contract.
//
//  This file is wrapped in `#if DEBUG` so it is stripped from release builds.
//

#if DEBUG
import Foundation

enum APIDecodeCheck {

    /// Dry-decode every response shape. Prints PASS/FAIL to the console.
    static func run() {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        check("/scan (full)")        { try decoder.decode(ScanResult.self, from: data(scanJSON)) }
        check("/scan (refused)")     { try decoder.decode(ScanResult.self, from: data(scanRefusedJSON)) }
        check("/ask (answered)")     { try decoder.decode(AskResult.self, from: data(askJSON)) }
        check("/ask (refused)")      { try decoder.decode(AskResult.self, from: data(askRefusedJSON)) }
        check("/scan/packet")        { try decoder.decode(PacketResult.self, from: data(packetJSON)) }
        check("/refusal-log")        { try decoder.decode(RefusalLog.self, from: data(refusalLogJSON)) }
        print("APIDecodeCheck complete.")
    }

    private static func data(_ json: String) -> Data { Data(json.utf8) }

    private static func check(_ name: String, _ decode: () throws -> Any) {
        do {
            _ = try decode()
            print("✅ decode OK: \(name)")
        } catch {
            print("❌ decode FAILED: \(name) — \(error)")
        }
    }

    // MARK: - Fixtures (shapes per docs/API_CONTRACT.md)

    /// Full /scan response — models the synthetic NTA (no scam flags, but the
    /// educational `scam_check_summary_es` is still present).
    static let scanJSON = """
    {
      "session_id": "11111111-1111-4111-8111-111111111111",
      "document_id": "22222222-2222-4222-8222-222222222222",
      "extraction": {
        "document_type": "Notice to Appear (Form I-862)",
        "issuing_agency": "U.S. Department of Justice — EOIR",
        "names_redacted": true,
        "a_number_redacted": true,
        "address_redacted": true,
        "country_of_origin": "Mexico",
        "country_of_citizenship": "Mexico",
        "hearing_date": "2026-10-15",
        "hearing_time": "09:00",
        "court_name": "Seattle Immigration Court",
        "court_address": "1000 Second Avenue, Suite 2900, Seattle, WA 98104",
        "issuing_officer": "Officer J. Sample",
        "alleged_basis_summary": "Overstay of B-2 admission",
        "charges_cited": ["INA section 237(a)(1)(B)"],
        "deadline_critical": "2026-10-15",
        "is_demo_document": true,
        "demo_watermark_detected": true
      },
      "summary_en": "A notice to appear in immigration court.",
      "summary_es": "Es un aviso para presentarte en la corte de inmigración.",
      "audio_url": "https://example.com/audio.mp3",
      "sections": [
        {
          "section_title_en": "Allegations",
          "section_title_es": "Acusaciones",
          "section_body_es": "El gobierno dice que te quedaste más tiempo.",
          "section_body_full_es": "El gobierno alega que permaneciste en EE. UU. más tiempo del permitido.",
          "citation_ids": ["c1"]
        }
      ],
      "urgency": {
        "is_urgent": true,
        "deadline_date": "2026-10-15",
        "deadline_label_es": "Fecha de corte: 15 de octubre de 2026, 9:00 AM",
        "verification_note_es": "Confirma la fecha con la corte directamente."
      },
      "scam_check_summary_es": "No detectamos señales de estafa en este documento.",
      "scam_red_flags": [],
      "court_brief": {
        "court_name": "Seattle Immigration Court",
        "address": "1000 Second Avenue, Suite 2900, Seattle, WA 98104",
        "phone": "206-200-0000",
        "what_to_expect_es": "Vas a ver a un juez de inmigración.",
        "what_to_bring_es": ["Identificación", "Este aviso"],
        "what_not_to_bring_es": ["Armas"],
        "dress_code_es": "Ropa formal o limpia."
      },
      "legal_aid_options": [
        {
          "name": "Northwest Immigrant Rights Project",
          "phone": "206-587-4009",
          "address": "615 Second Avenue, Suite 400, Seattle, WA 98104",
          "hours": "Lunes a viernes",
          "languages": ["Español"],
          "free": true
        }
      ],
      "citations": [
        { "id": "c1", "source_label": "EOIR Practice Manual", "kb_chunk_id": "eoir-01", "url": "https://example.com" }
      ],
      "latency_ms": 4200,
      "cost_estimate_usd": 0.03
    }
    """

    /// /scan refusal case — only the refusal fields are present.
    static let scanRefusedJSON = """
    {
      "session_id": "11111111-1111-4111-8111-111111111111",
      "was_refused": true,
      "refusal_reason": "document appears non-synthetic",
      "refusal_text_es": "No podemos analizar este documento.",
      "legal_aid_options": []
    }
    """

    /// /ask answered case.
    static let askJSON = """
    {
      "session_id": "11111111-1111-4111-8111-111111111111",
      "question_transcribed": "¿Qué es esto?",
      "answer_es": "Es un aviso de la corte de inmigración.",
      "answer_audio_url": "https://example.com/answer.mp3",
      "citations": [
        { "id": "c1", "source_label": "USCIS", "kb_chunk_id": "uscis-01" }
      ],
      "was_refused": false,
      "refusal_reason": null,
      "refusal_text_es": null,
      "legal_aid_options": [],
      "latency_ms": 1800
    }
    """

    /// /ask refusal case.
    static let askRefusedJSON = """
    {
      "session_id": "11111111-1111-4111-8111-111111111111",
      "question_transcribed": "¿Debo faltar a la audiencia?",
      "answer_es": null,
      "answer_audio_url": null,
      "citations": [],
      "was_refused": true,
      "refusal_reason": "hearing_attendance",
      "refusal_text_es": "No podemos aconsejarte sobre eso. Habla con un abogado.",
      "legal_aid_options": [
        {
          "name": "Colectiva Legal del Pueblo",
          "phone": "206-931-1514",
          "address": "13838 First Avenue S, Burien, WA 98168",
          "hours": "Lun, mar, jue, vie",
          "languages": ["Español"],
          "free": true
        }
      ],
      "latency_ms": 1500
    }
    """

    /// /scan/packet response.
    static let packetJSON = """
    {
      "session_id": "11111111-1111-4111-8111-111111111111",
      "packet": {
        "title_es": "Paquete de preparación",
        "what_this_says_es": "Este documento te pide presentarte en la corte.",
        "your_deadline": { "date": "2026-10-15", "label_es": "15 de octubre de 2026" },
        "documents_to_gather_es": ["Pasaporte", "Avisos anteriores"],
        "extension_request_template": "Yo, ___, solicito más tiempo...",
        "legal_aid_phone_script_es": "Hola, recibí un Notice to Appear...",
        "questions_for_lawyer_es": ["¿Qué significa la acusación?"],
        "cover_sheet_es": "Lleva este paquete a tu cita."
      },
      "legal_aid_options": [],
      "pdf_url": null
    }
    """

    /// /refusal-log response.
    static let refusalLogJSON = """
    {
      "session_id": "11111111-1111-4111-8111-111111111111",
      "count": 1,
      "refusals": [
        {
          "ts": "2026-05-16T20:00:00.000Z",
          "reason": "hearing_attendance",
          "topic_label_es": "Asistencia a la audiencia — derivado a ayuda legal"
        }
      ]
    }
    """
}
#endif
