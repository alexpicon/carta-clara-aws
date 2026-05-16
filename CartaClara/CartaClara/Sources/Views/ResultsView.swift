//
//  ResultsView.swift
//  Carta Clara
//
//  The scrollable result card stack shown after a successful scan.
//
//  Card order (DEMO_SCRIPT 0:25–0:55): summary, urgency, sections, then the
//  conditional scam and court cards, then the questions card and the actions.
//  Trust before features (TENETS.md §1): the demo badge and visible-redaction
//  confirmation come first.
//
//  If the scan itself was refused by Guardrails, this screen shows the safe
//  refusal text and routes straight to legal aid.
//

import SwiftUI

struct ResultsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var summaryAudio = AudioPlayback()

    var body: some View {
        Group {
            if let result = appState.scanResult {
                if result.isRefusal {
                    RefusedScanView(result: result)
                } else {
                    resultStack(result)
                }
            } else {
                // Defensive: we only reach this screen after a loaded scan.
                ErrorStateView(
                    message: UIText.errorGeneric,
                    retryable: false,
                    onRetry: nil
                )
            }
        }
        .background(CCColor.background)
        .navigationTitle(UIText.resultsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { summaryAudio.stop() }
    }

    // MARK: Normal result stack

    private func resultStack(_ result: ScanResult) -> some View {
        ScrollView {
            VStack(spacing: CCSpacing.md) {
                redactionConfirmation(result)

                if let summary = pickSummary(result), !summary.isEmpty {
                    SummaryCard(
                        summary: summary,
                        audioURL: result.audioUrl,
                        isDemo: result.extraction?.isDemoDocument == true,
                        playback: summaryAudio
                    )
                }

                if let urgency = result.urgency {
                    UrgencyCard(urgency: urgency)
                }

                readingLevelControl

                ForEach(result.sections ?? []) { section in
                    SectionCard(
                        section: section,
                        readingLevel: appState.readingLevel,
                        citations: citations(for: section, in: result)
                    )
                }

                if hasScamContent(result) {
                    ScamRedFlagCard(
                        summary: result.scamCheckSummaryEs,
                        flags: result.scamRedFlags ?? []
                    )
                }

                if let brief = result.courtBrief {
                    CourtBriefCard(brief: brief)
                }

                QuestionsCard {
                    appState.path.append(.packet)
                }

                actionButtons
            }
            .padding(CCSpacing.md)
        }
    }

    /// A small banner confirming the redaction the user just watched.
    private func redactionConfirmation(_ result: ScanResult) -> some View {
        let e = result.extraction
        let anyRedacted = (e?.namesRedacted ?? false)
            || (e?.aNumberRedacted ?? false)
            || (e?.addressRedacted ?? false)
        return Group {
            if anyRedacted {
                Label {
                    Text(UIText.redactionDone)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CCColor.success)
                } icon: {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(CCColor.success)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(CCSpacing.sm)
                .background(CCColor.success.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: CCRadius.control))
                .accessibilityElement(children: .combine)
                .accessibilityLabel(UIText.redactionDone)
            }
        }
    }

    /// The reading-level slider. Bound to AppState so it is shared session-wide.
    private var readingLevelControl: some View {
        CardContainer {
            Text(UIText.readingLevelLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CCColor.ink)
                .accessibilityAddTraits(.isHeader)
            Picker(UIText.readingLevelLabel, selection: $appState.readingLevel) {
                ForEach(ReadingLevel.allCases) { level in
                    Text(UIText.readingLevelName(level)).tag(level)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(UIText.readingLevelLabel)
            .accessibilityValue(UIText.readingLevelName(appState.readingLevel))
        }
    }

    private var actionButtons: some View {
        VStack(spacing: CCSpacing.md) {
            Button {
                appState.path.append(.ask)
            } label: {
                Label(UIText.askButton, systemImage: "bubble.left.and.text.bubble.right")
            }
            .buttonStyle(CCPrimaryButtonStyle())

            Button {
                appState.path.append(.packet)
            } label: {
                Label(UIText.helpRespondButton, systemImage: "doc.text.fill")
            }
            .buttonStyle(CCSecondaryButtonStyle())

            Button {
                appState.path.append(.legalHelp)
            } label: {
                Label(UIText.legalHelpButton, systemImage: "person.2.fill")
            }
            .buttonStyle(CCSecondaryButtonStyle())
        }
        .padding(.top, CCSpacing.sm)
    }

    /// True when there is a scam summary or any red flags to show. The scam
    /// card appears even with zero flags — the educational summary is always
    /// worth showing (see ScamRedFlagCard).
    private func hasScamContent(_ result: ScanResult) -> Bool {
        if let flags = result.scamRedFlags, !flags.isEmpty { return true }
        return result.scamCheckSummaryEs?.isEmpty == false
    }

    /// Pick the English summary in English-default mode, with the Spanish
    /// field as a fallback for backends that haven't been re-prompted yet.
    private func pickSummary(_ result: ScanResult) -> String? {
        if let en = result.summaryEn, !en.isEmpty { return en }
        return result.summaryEs
    }

    /// Resolve the Citation objects referenced by a section's `citation_ids`.
    private func citations(for section: DocumentSection, in result: ScanResult) -> [Citation] {
        guard let ids = section.citationIds, let all = result.citations else { return [] }
        let idSet = Set(ids)
        return all.filter { idSet.contains($0.id) }
    }
}

// MARK: - Refused scan

/// Shown when POST /scan returned `was_refused == true` — e.g. the document
/// appeared non-synthetic. Refuse before answering (TENETS.md §2): show the
/// safe text and route straight to a human.
private struct RefusedScanView: View {
    @EnvironmentObject private var appState: AppState
    let result: ScanResult

    var body: some View {
        ScrollView {
            VStack(spacing: CCSpacing.md) {
                CardContainer(accent: CCColor.urgent) {
                    CardTitle(
                        icon: "hand.raised.fill",
                        text: UIText.refusedScanTitle,
                        tint: CCColor.urgent
                    )
                    Text(result.refusalTextEs ?? "")
                        .font(.body)
                        .foregroundStyle(CCColor.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    appState.path.append(.legalHelp)
                } label: {
                    Label(UIText.legalHelpButton, systemImage: "person.2.fill")
                }
                .buttonStyle(CCPrimaryButtonStyle())
            }
            .padding(CCSpacing.md)
        }
    }
}
