//
//  CitationChip.swift
//  Carta Clara
//
//  A tappable source-citation chip.
//
//  Citations are the proof (TENETS.md §4): every grounded claim shows its
//  source, and the user can always tap to verify. This chip is that tap.
//

import SwiftUI

/// A small pill showing a cited source. Tapping opens the source URL.
struct CitationChip: View {
    let label: String
    let urlString: String?

    @Environment(\.openURL) private var openURL

    /// Build from a contract `Citation`.
    init(_ citation: Citation) {
        self.label = citation.sourceLabel
        self.urlString = citation.url
    }

    /// Build from a free label + URL (used by scam red-flag citations).
    init(label: String, urlString: String?) {
        self.label = label
        self.urlString = urlString
    }

    private var url: URL? { urlString.flatMap(URL.init(string:)) }

    var body: some View {
        Button {
            if let url { openURL(url) }
        } label: {
            HStack(spacing: CCSpacing.xs) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption2)
                    .accessibilityHidden(true)
                Text(label)
                    .font(.caption.weight(.medium))
                    .lineLimit(2)
                if url != nil {
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(CCColor.primary)
            .padding(.vertical, CCSpacing.xs + 2)
            .padding(.horizontal, CCSpacing.sm)
            .background(CCColor.chip)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(url == nil)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Fuente: \(label)")
        .accessibilityHint(url == nil ? "" : "Toca para abrir la fuente.")
        .accessibilityAddTraits(url == nil ? [] : .isLink)
    }
}

/// A wrapping row of citation chips.
struct CitationRow: View {
    let citations: [Citation]

    var body: some View {
        if !citations.isEmpty {
            VStack(alignment: .leading, spacing: CCSpacing.xs) {
                Text(UIText.citationsLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CCColor.inkSecondary)
                FlowLayout(spacing: CCSpacing.xs) {
                    ForEach(citations) { CitationChip($0) }
                }
            }
            .accessibilityElement(children: .contain)
        }
    }
}

/// A minimal flow layout so chips wrap onto multiple lines on small screens
/// and at large Dynamic Type sizes.
struct FlowLayout: Layout {
    var spacing: CGFloat = CCSpacing.xs

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                totalWidth = max(totalWidth, rowWidth - spacing)
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        totalWidth = max(totalWidth, rowWidth - spacing)
        return CGSize(width: min(totalWidth, maxWidth), height: totalHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: x, y: y),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
