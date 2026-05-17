//
//  RefusalLogView.swift
//  Carta Clara
//
//  The refusal log — what the app refused to answer this session, and why.
//
//  "It didn't refuse and walk away." (DEMO_SCRIPT 0:55). Tapping the refusal
//  counter opens this list. Every entry is a PII-redacted refusal event —
//  never document content (TENETS.md §7).
//

import SwiftUI

struct RefusalLogView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isLoading = false

    private var log: RefusalLog? { appState.refusalLog }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CCSpacing.md) {
                header
                    .ccAppear()

                if isLoading && log == nil {
                    LoadingView()
                        .frame(minHeight: 200)
                } else if let log, !log.refusals.isEmpty {
                    ForEach(Array(log.refusals.enumerated()), id: \.element.id) { offset, entry in
                        refusalRow(entry)
                            .ccAppear(index: offset + 1)
                    }
                } else {
                    EmptyStateView(
                        icon: "checkmark.shield.fill",
                        tint: CCColor.success,
                        message: UIText.refusalLogEmpty
                    )
                    .frame(minHeight: 200)
                    .ccAppear(index: 1)
                }
            }
            .padding(CCSpacing.md)
        }
        .background(CCGradient.warmPaper)
        .navigationTitle(UIText.refusalLogTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    CCHaptics.light()
                    appState.startFresh()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .accessibilityLabel("Scan another document")
            }
        }
        .task {
            isLoading = true
            await appState.refreshRefusalLog()
            isLoading = false
        }
    }

    /// Anchored hero — wraps the giant count in the same card chrome as the
    /// rows so the header feels grounded instead of floating.
    private var header: some View {
        CardContainer(accent: CCColor.urgent) {
            HStack(spacing: CCSpacing.md) {
                Image(systemName: "hand.raised.fill")
                    .font(.title)
                    .foregroundStyle(CCColor.urgent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(appState.refusalCount)")
                        .font(.system(size: 40, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(CCColor.ink)
                    Text(appState.refusalCount == 1
                         ? "question refused this session"
                         : "questions refused this session")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(CCColor.inkSecondary)
                }
            }
            Text(UIText.refusalLogIntro)
                .font(.body)
                .foregroundStyle(CCColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(appState.refusalCount) preguntas rechazadas. \(UIText.refusalLogIntro)")
    }

    private func refusalRow(_ entry: RefusalEntry) -> some View {
        CardContainer(accent: CCColor.urgent) {
            Label {
                Text(entry.topicLabelEs)
                    .font(.headline)
                    .foregroundStyle(CCColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "arrow.uturn.right.circle.fill")
                    .foregroundStyle(CCColor.urgent)
                    .accessibilityHidden(true)
            }
            Text(formattedTimestamp(entry.ts))
                .font(.caption)
                .foregroundStyle(CCColor.inkSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rechazada: \(entry.topicLabelEs). \(formattedTimestamp(entry.ts)).")
    }

    /// Format an ISO-8601 timestamp for display; fall back to the raw string.
    private func formattedTimestamp(_ iso: String) -> String {
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = parser.date(from: iso) ?? ISO8601DateFormatter().date(from: iso)
        guard let date else { return iso }
        let display = DateFormatter()
        display.locale = Locale(identifier: "es")
        display.dateStyle = .medium
        display.timeStyle = .short
        return display.string(from: date)
    }
}
