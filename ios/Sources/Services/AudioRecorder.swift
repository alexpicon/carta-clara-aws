//
//  AudioRecorder.swift
//  Carta Clara
//
//  Push-to-talk voice capture for the Ask screen.
//
//  Records 16 kHz mono PCM WAV — the format Amazon Transcribe expects and the
//  `audio_format: "wav"` value in the /ask contract. Voice input is the
//  DEFAULT way grandma asks a question (Press Release / grandma test).
//
//  Recordings are written to a temp file, read once, then deleted —
//  ephemeral by default (TENETS.md §7).
//

import AVFoundation
import Combine
import Foundation

/// Microphone permission status, mapped to the three UI states the Ask
/// screen must handle.
enum MicPermission {
    case granted
    case denied
    case undetermined
}

/// Observable push-to-talk recorder.
@MainActor
final class AudioRecorder: NSObject, ObservableObject {

    /// True between `startRecording()` and `stopRecording()`.
    @Published private(set) var isRecording = false
    /// True when the mic permission was denied — the UI shows a Settings prompt.
    @Published private(set) var permissionDenied = false

    private var recorder: AVAudioRecorder?
    private var fileURL: URL?

    /// Current microphone permission, without prompting.
    var permission: MicPermission {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: return .granted
        case .denied: return .denied
        default: return .undetermined
        }
    }

    /// Request microphone permission. Returns true if granted.
    func requestPermission() async -> Bool {
        let granted = await AVAudioApplication.requestRecordPermission()
        permissionDenied = !granted
        return granted
    }

    /// Begin recording. No-op if permission is missing or already recording.
    func startRecording() {
        guard !isRecording else { return }
        guard permission == .granted else {
            permissionDenied = true
            return
        }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            return
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("cc-question-\(UUID().uuidString).wav")
        // 16 kHz mono PCM — small, and exactly what Transcribe wants.
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16_000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]
        do {
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.delegate = self
            guard recorder.record() else { return }
            self.recorder = recorder
            self.fileURL = url
            isRecording = true
        } catch {
            isRecording = false
        }
    }

    /// Stop recording and return the captured WAV bytes. The temp file is
    /// deleted before returning. Returns nil if nothing usable was recorded.
    @discardableResult
    func stopRecording() -> Data? {
        guard isRecording, let recorder, let fileURL else {
            isRecording = false
            return nil
        }
        recorder.stop()
        isRecording = false
        self.recorder = nil
        self.fileURL = nil

        defer { try? FileManager.default.removeItem(at: fileURL) }
        guard let data = try? Data(contentsOf: fileURL), !data.isEmpty else {
            return nil
        }
        return data
    }

    /// Discard an in-progress recording without returning data (cancel gesture).
    func cancelRecording() {
        guard let recorder, let fileURL else { return }
        recorder.stop()
        try? FileManager.default.removeItem(at: fileURL)
        self.recorder = nil
        self.fileURL = nil
        isRecording = false
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(
        _ recorder: AVAudioRecorder,
        successfully flag: Bool
    ) {
        Task { @MainActor in self.isRecording = false }
    }
}
