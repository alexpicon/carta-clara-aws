//
//  SectionCard.swift
//  Carta Clara
//
//  An expandable section card — one per part of the document.
//
//  The body text is reading-level-tuned: the slider in ResultsView chooses
//  between the plain (`section_body_es`) and full-detail (`section_body_full_es`)
//  Spanish the backend produced. Every section can carry citations.
//

import SwiftUI

/// One collapsible document-section card.
struct SectionCard: View {
    let section: DocumentSection
    let readingLevel: ReadingLevel
    /// Citations already resolved for this section's `citation_ids`.
    let citations: [Citation]
    /// SF Symbol for the card's title. Per-section icons differentiate the
    /// 4 mandatory sections visually (calendar for dates, building for
    /// agency, magnifying-glass for allegations, scale for rights).
    var icon: String = "doc.text"
    /// Active content language — drives the per-card TTS voice selection.
    var language: AppLanguage = .english

    @State private var expanded = false

    private var bodyText: String { section.body(for: readingLevel) }
    /// Stable id for the shared SpeechSynthesizer to track which card is
    /// currently being read aloud.
    private var ttsId: String { "section:\(section.sectionTitleEn)" }

    var body: some View {
        CardContainer {
            HStack(alignment: .firstTextBaseline, spacing: CCSpacing.xs) {
                Button {
                    CCHaptics.soft()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        expanded.toggle()
                    }
                } label: {
                    HStack(alignment: .firstTextBaseline) {
                        CardTitle(icon: icon, text: section.sectionTitleEs)
                        Spacer()
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CCColor.primary)
                            .accessibilityHidden(true)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(section.sectionTitleEs)
                .accessibilityValue(expanded ? UIText.sectionExpandedA11y : UIText.sectionCollapsedA11y)
                .accessibilityHint(expanded ? UIText.sectionCollapse : UIText.sectionExpand)
                .accessibilityAddTraits(.isButton)

                CardTTSButton(id: ttsId, text: bodyText, language: language)
            }

            Text(bodyText)
                .font(.body)
                .foregroundStyle(CCColor.ink)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(expanded ? nil : 3)

            if expanded {
                if !citations.isEmpty {
                    CitationRow(citations: citations)
                        .padding(.top, CCSpacing.xs)
                }
            } else if bodyText.count > 140 {
                Text(UIText.sectionExpand)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CCColor.primary)
            }
        }
    }
}
