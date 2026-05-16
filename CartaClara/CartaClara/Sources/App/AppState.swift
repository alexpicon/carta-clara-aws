//
//  AppState.swift
//  Carta Clara
//
//  The single source of truth for navigation and session state.
//
//  One AppState lives for the lifetime of the app and is injected as an
//  @EnvironmentObject. It owns: the navigation path, the session id, the
//  captured image, the scan result, and the refusal counter.
//
//  Ephemeral by default (TENETS.md §7): nothing here is persisted to disk.
//  Killing the app drops the session — exactly what we want for documents.
//

import Combine
import SwiftUI
import UIKit

// MARK: - Routes

/// Destinations on the navigation stack. The splash screen is the stack root
/// and is therefore not a case here.
enum Route: Hashable {
    case camera
    /// Redaction animation + scan in flight.
    case processing
    case results
    case ask
    case refusalLog
    case packet
    case legalHelp
}

// MARK: - Load state

/// Generic async load state for a screen-level request.
enum LoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed(message: String, retryable: Bool)

    static func == (lhs: LoadState, rhs: LoadState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.loaded, .loaded):
            return true
        case let (.failed(lm, lr), .failed(rm, rr)):
            return lm == rm && lr == rr
        default:
            return false
        }
    }
}

// MARK: - AppState

@MainActor
final class AppState: ObservableObject {

    // Navigation
    @Published var path: [Route] = []

    // Session — minted on launch, replaced by the backend's echo after /scan.
    @Published private(set) var sessionId: String = UUID().uuidString

    // Reading-level slider binding, shared across the results cards.
    @Published var readingLevel: ReadingLevel = .intermediate

    // Scan pipeline
    @Published var capturedImage: UIImage?
    @Published private(set) var scanResult: ScanResult?
    @Published private(set) var scanState: LoadState = .idle

    // Refusal counter — the trust story compressed into one number.
    @Published private(set) var refusalCount: Int = 0
    @Published private(set) var refusalLog: RefusalLog?

    let api: CartaClaraAPI

    init(api: CartaClaraAPI = .shared) {
        self.api = api
    }

    /// Asset name for the bundled synthetic NTA used by the demo safety net
    /// (RIKU-17). Alex adds `NTA_demo.jpg` (or an asset-catalog image of this
    /// name) to the app target — see ios/README.md.
    static let demoDocumentAssetName = "NTA_demo"

    /// Load the bundled synthetic demo document into the scan pipeline,
    /// bypassing the camera. Returns false if the image is not in the bundle.
    ///
    /// This is the on-stage safety net: if the camera fails live, this keeps
    /// the demo running against the exact same /scan flow.
    func loadDemoDocument() -> Bool {
        guard let image = UIImage(named: Self.demoDocumentAssetName) else {
            return false
        }
        startNewScan()
        capturedImage = image
        path.append(.processing)
        return true
    }

    /// True once Configuration.plist has a real API_BASE_URL.
    var isBackendConfigured: Bool { api.isConfigured }

    /// The scanned document id, if a scan has succeeded.
    var documentId: String? { scanResult?.documentId }

    // MARK: Scan

    /// Run the document scan. Called by RedactionAnimationView once the user
    /// has confirmed a photo. Safe to call once per captured image.
    func performScan() async {
        guard let image = capturedImage else {
            scanState = .failed(message: UIText.errorGeneric, retryable: false)
            return
        }
        scanState = .loading
        do {
            let result = try await api.scan(
                image: image,
                readingLevel: readingLevel,
                sessionId: sessionId
            )
            // Adopt the backend's session id so /ask and /refusal-log line up.
            sessionId = result.sessionId
            scanResult = result
            scanState = .loaded
            // A refused scan still counts as a visible refusal.
            if result.isRefusal {
                refusalCount += 1
            }
        } catch let error as APIError {
            scanState = .failed(
                message: Self.userMessage(for: error),
                retryable: error.isRetryable
            )
        } catch {
            scanState = .failed(message: UIText.errorGeneric, retryable: true)
        }
    }

    // MARK: Refusals

    /// Record a refusal observed in an /ask response. Increments the visible
    /// counter immediately (demo-critical: the tick must be instant), then
    /// reconciles with the authoritative server log.
    func registerRefusal() {
        refusalCount += 1
        Task { await refreshRefusalLog() }
    }

    /// Pull the authoritative refusal log for this session.
    func refreshRefusalLog() async {
        do {
            let log = try await api.refusalLog(sessionId: sessionId)
            refusalLog = log
            // The server log is authoritative, but never let the visible
            // counter move backwards mid-demo.
            refusalCount = max(refusalCount, log.count)
        } catch {
            // A failed poll is non-fatal — keep the local count and the last
            // good log. The counter stays usable offline.
        }
    }

    // MARK: Reset

    /// Clear the document state to scan a fresh one. The session id and the
    /// refusal counter persist — the counter is a per-session trust artifact.
    func startNewScan() {
        capturedImage = nil
        scanResult = nil
        scanState = .idle
    }

    /// Pop back to the splash root.
    func goHome() {
        path.removeAll()
    }

    // MARK: Helpers

    /// Map an APIError to a calm, Spanish, grandma-readable message.
    static func userMessage(for error: APIError) -> String {
        switch error {
        case .missingConfiguration:
            return UIText.errorNotConfigured
        case .transport:
            return UIText.errorOffline
        default:
            return UIText.errorGeneric
        }
    }
}
