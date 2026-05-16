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

    @State private var expanded = false

    private var bodyText: String { section.body(for: readingLevel) }

    var body: some View {
        CardContainer {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    CardTitle(icon: "doc.text", text: section.sectionTitleEs)
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
            .accessibilityValue(expanded ? "Desplegado" : "Contraído")
            .accessibilityHint(expanded ? UIText.sectionCollapse : UIText.sectionExpand)
            .accessibilityAddTraits(.isButton)

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
