//
//  SummaryCard.swift
//  Carta Clara
//
//  The headline-summary card — the first thing the user sees in the results.
//
//  Shows the plain-Spanish 1–2 sentence summary and a large play button that
//  reads it aloud (Polly audio). Audio playback is core accessibility: the
//  grandma test assumes she may prefer to listen (Press Release).
//
//  All Spanish content here is read straight from the /scan response — never
//  composed on-device.
//

import SwiftUI

/// Headline summary card with audio playback.
struct SummaryCard: View {
    /// Plain-Spanish headline summary (`summary_es`).
    let summaryEs: String
    /// Presigned Polly audio URL (`audio_url`), or nil if unavailable.
    let audioURL: String?
    /// True when the backend flagged this as a demo document.
    let isDemo: Bool
    /// Shared playback engine for this clip.
    @ObservedObject var playback: AudioPlayback

    var body: some View {
        CardContainer {
            HStack {
                CardTitle(icon: "text.bubble.fill", text: "Resumen")
                Spacer()
                if isDemo { DemoBadge() }
            }

            Text(summaryEs)
                .font(.title3)
                .foregroundStyle(CCColor.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Resumen: \(summaryEs)")

            if audioURL != nil {
                playButton
            }
        }
    }

    private var playButton: some View {
        Button {
            playback.toggle(urlString: audioURL)
        } label: {
            HStack(spacing: CCSpacing.sm) {
                if playback.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(CCColor.onPrimary)
                } else {
                    Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                        .font(.headline)
                }
                Text(playback.isPlaying ? UIText.pauseSummary : UIText.playSummary)
            }
        }
        .buttonStyle(CCPrimaryButtonStyle())
        .padding(.top, CCSpacing.xs)
        .accessibilityLabel(playback.isPlaying ? UIText.pauseSummary : UIText.playSummary)
        .accessibilityHint(playback.failed ? "El audio no se pudo reproducir." : "")
    }
}
