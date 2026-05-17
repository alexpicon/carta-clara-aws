//
//  CardTTSButton.swift
//  Carta Clara
//
//  Small speaker icon that reads a card's text aloud via the shared
//  SpeechSynthesizer. Dropped into the title row of any text-bearing card
//  so the user can listen to it without leaving the screen.
//
//  Behavior:
//    - Idle: gray speaker icon.
//    - Speaking: blue speaker-wave icon, gentle pulse.
//    - Tap again while speaking → stop.
//    - Tap a different card → previous card stops, new one starts.
//
//  The summary card keeps its larger Polly-backed pill ("Listen to the
//  summary") as the hero voice — this button is the universal helper.
//

import SwiftUI

struct CardTTSButton: View {
    /// Stable identifier for this card — used by the synthesizer to know
    /// which card is currently speaking. Section title works well.
    let id: String
    /// The text the button should read aloud when tapped.
    let text: String
    /// Language the text is in. Drives voice selection.
    let language: AppLanguage

    @EnvironmentObject private var speech: SpeechSynthesizer
    @State private var pulse = false

    var body: some View {
        let active = speech.isSpeaking(id: id)
        Button {
            CCHaptics.soft()
            speech.toggle(id: id, text: text, language: language)
        } label: {
            Image(systemName: active ? "speaker.wave.2.fill" : "speaker.wave.2")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(active ? CCColor.primary : CCColor.inkSecondary.opacity(0.7))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(active ? CCColor.primary.opacity(0.12) : Color.clear)
                )
                .scaleEffect(active && pulse ? 1.08 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(active ? "Stop reading aloud" : "Read aloud")
        .accessibilityHint("Reads the card's text aloud in the chosen language.")
        // Don't double up with VoiceOver — users on VoiceOver / Speak Screen
        // already have the OS-level TTS for the whole screen.
        .accessibilityHidden(UIAccessibility.isVoiceOverRunning)
        .onChange(of: active) { _, isActive in
            if isActive {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            } else {
                pulse = false
            }
        }
    }
}
