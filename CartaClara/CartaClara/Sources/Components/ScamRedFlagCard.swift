//
//  ScamRedFlagCard.swift
//  Carta Clara
//
//  The scam / notario red-flag card.
//
//  Two parts:
//   • An educational Spanish summary (`scam_check_summary_es`) — shown even
//     when zero flags were detected, so the user is always taught what to
//     watch for (see docs/synthetic-docs/NTA_demo.md).
//   • A list of detected red-flag patterns, each cited to a public FTC or
//     USCIS advisory.
//
//  We NEVER accuse anyone of fraud — we only surface patterns and cite the
//  source. Citations are the proof (TENETS §4).
//

import SwiftUI

/// Shown whenever the scan returned a scam summary and/or red-flag patterns.
/// Reassuring (green) when no flags were found; cautioning (amber) when flags
/// are present.
struct ScamRedFlagCard: View {
    /// Educational scam message — always shown if present.
    let summary: String?
    /// Detected red-flag patterns. May be empty.
    let flags: [ScamRedFlag]

    private var hasFlags: Bool { !flags.isEmpty }
    private var accent: Color { hasFlags ? CCColor.caution : CCColor.success }

    var body: some View {
        CardContainer(accent: accent) {
            CardTitle(
                icon: hasFlags ? "exclamationmark.shield.fill" : "checkmark.shield.fill",
                text: hasFlags ? UIText.scamCardTitleAlert : UIText.scamCardTitleSafe,
                tint: accent
            )

            if let summary, !summary.isEmpty {
                Text(summary)
                    .font(.body)
                    .foregroundStyle(CCColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if hasFlags {
                if summary?.isEmpty == false {
                    Divider().padding(.vertical, CCSpacing.xs)
                }
                ForEach(flags) { flag in
                    flagRow(flag)
                    if flag.id != flags.last?.id {
                        Divider().padding(.vertical, CCSpacing.xs)
                    }
                }
            }
        }
    }

    private func flagRow(_ flag: ScamRedFlag) -> some View {
        VStack(alignment: .leading, spacing: CCSpacing.xs) {
            Label {
                Text(flag.patternDescriptionEs)
                    .font(.body)
                    .foregroundStyle(CCColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "flag.fill")
                    .foregroundStyle(CCColor.caution)
                    .accessibilityHidden(true)
            }

            if flag.citationUrl != nil || flag.citationSource != nil {
                CitationChip(
                    label: flag.citationSource ?? "Fuente",
                    urlString: flag.citationUrl
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
