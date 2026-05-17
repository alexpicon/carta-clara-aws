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
    /// Language picker shown after photo confirmation, before the scan runs.
    case languagePicker
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

    // Output language for the results, set by LanguagePickerView between
    // photo confirmation and the scan call. Also drives UI chrome language
    // — the didSet flips UIText.currentLanguage so every screen the user
    // sees after the picker renders in the chosen language.
    @Published var selectedLanguage: AppLanguage = .english {
        didSet { UIText.currentLanguage = selectedLanguage }
    }

    // Scan pipeline
    @Published var capturedImage: UIImage?
    @Published private(set) var scanResult: ScanResult?
    @Published private(set) var scanState: LoadState = .idle

    // Refusal counter — the trust story compressed into one number.
    @Published private(set) var refusalCount: Int = 0
    @Published private(set) var refusalLog: RefusalLog?

    // Packet pre-fetch — kicked off automatically when a scan succeeds so
    // that tapping "Help me respond" feels instant instead of waiting 10-14s
    // for the second model call. ResponsePacketView reads from here; on miss
    // it falls back to a fresh /scan/packet call (resilience).
    @Published private(set) var cachedPacket: PacketResult?
    private var packetPrefetchTask: Task<Void, Never>?

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
        path.append(.languagePicker)
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
                language: selectedLanguage,
                sessionId: sessionId
            )
            // Adopt the backend's session id so /ask and /refusal-log line up.
            sessionId = result.sessionId
            scanResult = result
            scanState = .loaded
            // A refused scan still counts as a visible refusal.
            if result.isRefusal {
                refusalCount += 1
            } else {
                // Pre-fetch the preparation packet in the background. By the
                // time the user taps "Help me respond" it's usually ready
                // and renders instantly instead of spinning for 10-14s.
                prefetchPacket()
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
        cachedPacket = nil
        packetPrefetchTask?.cancel()
        packetPrefetchTask = nil
    }

    /// Kick off a /scan/packet call in the background and cache the result.
    /// Called from performScan() the moment a non-refused scan lands so the
    /// packet is usually already loaded by the time the user taps to view it.
    /// Silent failures — ResponsePacketView falls back to a fresh call.
    private func prefetchPacket() {
        guard let documentId = scanResult?.documentId else { return }
        packetPrefetchTask?.cancel()
        packetPrefetchTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let packet = try await self.api.packet(
                    sessionId: self.sessionId,
                    documentId: documentId,
                    extraction: self.scanResult?.extraction,
                    summaryEs: self.scanResult?.summaryEs,
                    summaryEn: self.scanResult?.summaryEn,
                    language: self.selectedLanguage
                )
                guard !Task.isCancelled else { return }
                self.cachedPacket = packet
            } catch {
                // Silent — the user will retry via the regular fetch path
                // when they tap "Help me respond". Pre-fetch is best-effort.
            }
        }
    }

    /// Pop back to the splash root.
    func goHome() {
        path.removeAll()
    }

    /// Reset to a fresh scan from anywhere in the stack. Clears scan state
    /// and pops the entire navigation stack so the user lands back on the
    /// Splash screen (the home). One extra tap to start a new scan, but the
    /// home gives context: the wordmark, the disclaimer, and the deliberate
    /// "Start scanning" CTA. Refusal counter is preserved (it's a session
    /// trust artifact, not per-scan state).
    func startFresh() {
        startNewScan()
        path = []
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
