//
//  SummaryCard.swift
//  Carta Clara
//
//  The headline-summary card — the first thing the user sees in the results.
//
//  Shows the 1–2 sentence headline summary and a large play button that
//  reads the Spanish version aloud (Polly audio). Audio playback is core
//  accessibility: the grandma test assumes she may prefer to listen (Press
//  Release). Text body is English while the app is in English-default mode
//  (TENETS.md §9); Polly audio remains Spanish for the bilingual helper.
//
//  All content here is read straight from the /scan response — never
//  composed on-device.
//

import SwiftUI

/// Headline summary card with audio playback.
struct SummaryCard: View {
    /// Headline summary text to display (English while in dev-mode default).
    let summary: String
    /// Presigned Polly audio URL (`audio_url`), or nil if unavailable.
    let audioURL: String?
    /// True when the backend flagged this as a demo document.
    let isDemo: Bool
    /// Shared playback engine for this clip.
    @ObservedObject var playback: AudioPlayback

    var body: some View {
        CardContainer {
            HStack {
                CardTitle(icon: "text.bubble.fill", text: UIText.summaryCardTitle)
                Spacer()
                if isDemo { DemoBadge() }
            }

            Text(summary)
                .font(.title3)
                .foregroundStyle(CCColor.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("\(UIText.summaryA11yPrefix): \(summary)")

            if audioURL != nil {
                HStack {
                    Spacer()
                    playButton
                }
                .padding(.top, CCSpacing.xs)
            }
        }
    }

    /// Compact pill-shaped play/pause control. Trailing-aligned so it
    /// supports the headline summary instead of visually dominating the
    /// card the way the previous full-width primary button did.
    private var playButton: some View {
        Button {
            CCHaptics.soft()
            playback.toggle(urlString: audioURL)
        } label: {
            HStack(spacing: CCSpacing.xs) {
                if playback.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(CCColor.onPrimary)
                } else {
                    Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                        .font(.subheadline.weight(.semibold))
                }
                Text(playback.isPlaying ? UIText.pauseSummary : UIText.playSummary)
            }
        }
        .buttonStyle(CCInlineButtonStyle())
        .accessibilityLabel(playback.isPlaying ? UIText.pauseSummary : UIText.playSummary)
        .accessibilityHint(playback.failed ? "El audio no se pudo reproducir." : "")
    }
}
