//
//  CartaClaraAPI.swift
//  Carta Clara
//
//  async/await REST client for the Carta Clara backend.
//
//  Endpoints (see docs/API_CONTRACT.md):
//    POST /scan         — scan a document image
//    POST /ask          — ask a follow-up question (text or voice)
//    POST /scan/packet  — generate the Response Preparation Packet
//    GET  /refusal-log  — count + recent refusals for a session
//
//  Base URL is read from Configuration.plist (key `API_BASE_URL`), which Alex
//  fills in after `sam deploy`.
//

import Foundation
import UIKit

// MARK: - Errors

/// Errors surfaced to the UI layer. Every case carries a Spanish-safe story:
/// the views map these to error states, but the *message text shown to the
/// user* is owned by `UIText` (UI chrome) — never a raw error string.
enum APIError: LocalizedError {
    /// Configuration.plist is missing or has a placeholder API_BASE_URL.
    case missingConfiguration
    /// Could not build a request URL.
    case badURL
    /// Could not encode the image (too large, or conversion failed).
    case imageEncodingFailed
    /// Transport failure (offline, DNS, timeout).
    case transport(Error)
    /// Non-2xx HTTP response. `serverMessage` is the contract `error` field.
    case http(status: Int, serverMessage: String?)
    /// Response body did not match the expected shape.
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "API_BASE_URL is not configured in Configuration.plist."
        case .badURL:
            return "Could not construct the request URL."
        case .imageEncodingFailed:
            return "The photo could not be prepared for upload."
        case .transport(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        case .http(let status, let serverMessage):
            return "Server returned \(status)\(serverMessage.map { ": \($0)" } ?? "")."
        case .decoding(let underlying):
            return "Unexpected response shape: \(underlying.localizedDescription)"
        }
    }

    /// True for conditions a retry could plausibly fix (offline, throttle, 5xx).
    var isRetryable: Bool {
        switch self {
        case .transport:
            return true
        case .http(let status, _):
            return status == 429 || (500...599).contains(status)
        default:
            return false
        }
    }
}

// MARK: - Configuration

/// Loads runtime configuration from `Configuration.plist`.
enum AppConfiguration {
    /// Sentinel value shipped in the template plist. Treated as "not configured."
    static let placeholder = "REPLACE_WITH_SAM_DEPLOY_OUTPUT"

    /// The API base URL, or nil if not yet configured.
    static var apiBaseURL: URL? {
        guard
            let url = Bundle.main.url(forResource: "Configuration", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
            let dict = plist as? [String: Any],
            let raw = dict["API_BASE_URL"] as? String,
            !raw.isEmpty,
            raw != placeholder
        else {
            return nil
        }
        // Tolerate a trailing slash in the configured value.
        let trimmed = raw.hasSuffix("/") ? String(raw.dropLast()) : raw
        return URL(string: trimmed)
    }
}

// MARK: - Client

/// Stateless REST client. Inject a custom `URLSession` in tests.
final class CartaClaraAPI {

    /// Shared instance used by AppState.
    static let shared = CartaClaraAPI()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session

        let decoder = JSONDecoder()
        // The contract uses snake_case; models are camelCase.
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = encoder
    }

    /// True once Alex has filled in Configuration.plist. The UI uses this to
    /// show a clear "not configured" state instead of a confusing error.
    var isConfigured: Bool { AppConfiguration.apiBaseURL != nil }

    // MARK: POST /scan

    /// Submit a photographed document for extraction, summary, and translation.
    ///
    /// - Parameters:
    ///   - image: the captured document photo.
    ///   - readingLevel: Spanish complexity for the summary/sections.
    ///   - sessionId: reuse an existing session, or nil to let the backend mint one.
    func scan(
        image: UIImage,
        readingLevel: ReadingLevel = .intermediate,
        language: AppLanguage = .english,
        sessionId: String? = nil
    ) async throws -> ScanResult {
        guard let base64 = Self.jpegBase64(from: image) else {
            throw APIError.imageEncodingFailed
        }
        struct Body: Encodable {
            let sessionId: String?
            let imageBase64: String
            let readingLevel: String
            let language: String
        }
        let body = Body(
            sessionId: sessionId,
            imageBase64: base64,
            readingLevel: readingLevel.rawValue,
            language: language.rawValue
        )
        return try await post(path: "/scan", body: body, as: ScanResult.self)
    }

    // MARK: POST /ask

    /// Ask a follow-up question about a scanned document. Provide exactly one
    /// of `question` (text) or `audioData` (voice).
    func ask(
        sessionId: String,
        documentId: String,
        question: String? = nil,
        audioData: Data? = nil,
        audioFormat: String = "wav"
    ) async throws -> AskResult {
        struct Body: Encodable {
            let sessionId: String
            let documentId: String
            let question: String?
            let audioBase64: String?
            let audioFormat: String?
        }
        let body = Body(
            sessionId: sessionId,
            documentId: documentId,
            question: question,
            audioBase64: audioData?.base64EncodedString(),
            audioFormat: audioData == nil ? nil : audioFormat
        )
        return try await post(path: "/ask", body: body, as: AskResult.self)
    }

    // MARK: POST /scan/packet

    /// Generate the Response Preparation Packet for a scanned document.
    ///
    /// Passing `extraction` (and ideally `summaryEs`/`summaryEn`) lets the
    /// backend skip re-OCRing the image — text-only Bedrock finishes in
    /// ~10-14s instead of the 31-37s multimodal path that times out at
    /// API Gateway's 30s ceiling. Always pass them when you have them.
    func packet(
        sessionId: String,
        documentId: String,
        extraction: Extraction? = nil,
        summaryEs: String? = nil,
        summaryEn: String? = nil,
        language: AppLanguage = .english
    ) async throws -> PacketResult {
        struct SummaryStub: Encodable {
            let summaryEs: String?
            let summaryEn: String?
        }
        struct Body: Encodable {
            let sessionId: String
            let documentId: String
            let language: String
            let extraction: Extraction?
            let summary: SummaryStub?
        }
        let summary: SummaryStub? = (summaryEs != nil || summaryEn != nil)
            ? SummaryStub(summaryEs: summaryEs, summaryEn: summaryEn)
            : nil
        let body = Body(
            sessionId: sessionId,
            documentId: documentId,
            language: language.rawValue,
            extraction: extraction,
            summary: summary
        )
        return try await post(path: "/scan/packet", body: body, as: PacketResult.self)
    }

    // MARK: GET /refusal-log

    /// Fetch the refusal count and recent refusals for a session.
    func refusalLog(sessionId: String) async throws -> RefusalLog {
        guard let base = AppConfiguration.apiBaseURL else {
            throw APIError.missingConfiguration
        }
        guard var components = URLComponents(
            url: base.appendingPathComponent("refusal-log"),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.badURL
        }
        components.queryItems = [URLQueryItem(name: "session_id", value: sessionId)]
        guard let url = components.url else { throw APIError.badURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        return try await send(request, as: RefusalLog.self)
    }

    // MARK: - Internals

    /// Encode `body` as JSON and POST it to `path`, decoding the response.
    private func post<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body,
        as type: Response.Type
    ) async throws -> Response {
        guard let base = AppConfiguration.apiBaseURL else {
            throw APIError.missingConfiguration
        }
        let url = base.appendingPathComponent(path.hasPrefix("/") ? String(path.dropFirst()) : path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // Document scans can be slow (multimodal + Polly). Be patient.
        request.timeoutInterval = 60

        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            throw APIError.decoding(error)
        }
        return try await send(request, as: type)
    }

    /// Execute a request and decode the response, mapping failures to APIError.
    private func send<Response: Decodable>(
        _ request: URLRequest,
        as type: Response.Type
    ) async throws -> Response {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.http(status: -1, serverMessage: nil)
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.http(
                status: http.statusCode,
                serverMessage: Self.serverErrorMessage(from: data)
            )
        }
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    /// Pull the `error` field out of a contract error body, if present.
    private static func serverErrorMessage(from data: Data) -> String? {
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return object["error"] as? String
    }

    /// Encode an image as base64 JPEG. The 4.5MB raw cap fits Bedrock's 5MB
    /// per-image hard limit (decoded bytes) with headroom — strictest of the
    /// chain, stricter than API Gateway's 10MB body limit.
    static func jpegBase64(from image: UIImage, maxBytes: Int = 4_500_000) -> String? {
        let resized = downscale(image, longestEdge: 1_400)
        var quality: CGFloat = 0.70
        var data = resized.jpegData(compressionQuality: quality)
        while let current = data, current.count > maxBytes, quality > 0.3 {
            quality -= 0.15
            data = resized.jpegData(compressionQuality: quality)
        }
        guard let final = data, final.count <= maxBytes else { return nil }
        return final.base64EncodedString()
    }

    /// Proportionally downscale so the longest edge is at most `longestEdge`.
    private static func downscale(_ image: UIImage, longestEdge: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > longestEdge else { return image }
        let scale = longestEdge / longest
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
