//
//  SpeechSynthesizer.swift
//  Carta Clara
//
//  Per-card text-to-speech via Apple's on-device AVSpeechSynthesizer.
//
//  Why on-device (not Polly): every section card and chat bubble can have a
//  speaker button without adding a single network call, a single S3 object,
//  or a single dollar to the per-scan cost. The summary card keeps its
//  hero Polly Lupe / Joanna voice for the demo "wow" moment; everything
//  else uses the same accessibility voice the user already hears from
//  iOS Speak Screen.
//
//  Voice selection: matches AppState.selectedLanguage. Spanish picks the
//  best available es-* voice ("Mónica" / "Paulina" / enhanced fallbacks),
//  English picks the best en-US ("Samantha" / Siri voices on iOS 17+).
//
//  Concurrency: one card speaks at a time. Tapping a new card stops the
//  previous. Tapping the same card again pauses; tapping again resumes —
//  no, simpler: tapping the same card again stops. Less state to manage.
//

import AVFoundation
import Combine

@MainActor
final class SpeechSynthesizer: NSObject, ObservableObject {
    /// `id` of the card / bubble currently speaking, or nil. Views observe
    /// this to flip their speaker icon between idle and playing state.
    @Published private(set) var speakingId: String?

    private let synth = AVSpeechSynthesizer()

    override init() {
        super.init()
        synth.delegate = self
    }

    // MARK: Public

    /// Toggle TTS for a card identified by `id`. If the same id is already
    /// speaking, this stops it. If a different id is speaking, that one is
    /// cancelled and the new one starts.
    func toggle(id: String, text: String, language: AppLanguage) {
        if speakingId == id {
            stop()
            return
        }
        speak(id: id, text: text, language: language)
    }

    /// True when the given card id is the one currently speaking.
    func isSpeaking(id: String) -> Bool {
        speakingId == id && synth.isSpeaking
    }

    /// Stop any active utterance and clear state.
    func stop() {
        if synth.isSpeaking || synth.isPaused {
            synth.stopSpeaking(at: .immediate)
        }
        speakingId = nil
    }

    // MARK: Internal

    private func speak(id: String, text: String, language: AppLanguage) {
        // Cancel any in-flight utterance — only one card speaks at a time.
        if synth.isSpeaking || synth.isPaused {
            synth.stopSpeaking(at: .immediate)
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = Self.bestVoice(for: language)
        // Apple's default 0.5 is too brisk for a 5th-grade-reading-level
        // audience; 0.46 slows it just enough to feel calm without
        // sounding sluggish.
        utterance.rate = 0.46
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0
        utterance.postUtteranceDelay = 0

        speakingId = id
        synth.speak(utterance)
    }

    /// Pick the best on-device voice for the given language. Prefers the
    /// enhanced/premium voice when the user has downloaded one (iOS Settings
    /// → Accessibility → Spoken Content → Voices); falls back to whatever
    /// is installed.
    private static func bestVoice(for language: AppLanguage) -> AVSpeechSynthesisVoice? {
        let preferredCodes: [String]
        switch language {
        case .spanish:
            preferredCodes = ["es-MX", "es-US", "es-ES", "es"]
        case .english:
            preferredCodes = ["en-US", "en"]
        }
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        for code in preferredCodes {
            // Prefer enhanced/premium quality if the user has it installed.
            let enhanced = allVoices.first { $0.language.hasPrefix(code) && $0.quality != .default }
            if let enhanced { return enhanced }
            let any = allVoices.first { $0.language.hasPrefix(code) }
            if let any { return any }
        }
        // Last-resort fallback — let iOS pick.
        return AVSpeechSynthesisVoice(language: preferredCodes.first ?? "en-US")
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SpeechSynthesizer: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in self.speakingId = nil }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in self.speakingId = nil }
    }
}
