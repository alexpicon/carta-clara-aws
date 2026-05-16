//
//  CourtBriefCard.swift
//  Carta Clara
//
//  The "what to expect at this courthouse" brief.
//
//  Explains the courthouse named in the document — address, what to expect,
//  what to bring, what to wear. It NEVER analyzes the judge or predicts an
//  outcome (TENETS.md bright lines: no judge analytics, ever).
//

import SwiftUI

/// Conditional card — shown only when the scan returned a `court_brief`.
struct CourtBriefCard: View {
    let brief: CourtBrief

    @Environment(\.openURL) private var openURL

    var body: some View {
        CardContainer(accent: CCColor.primary) {
            CardTitle(icon: "building.columns.fill", text: UIText.courtBriefTitle)

            VStack(alignment: .leading, spacing: CCSpacing.xs) {
                Text(brief.courtName)
                    .font(.headline)
                    .foregroundStyle(CCColor.ink)
                Text(brief.address)
                    .font(.subheadline)
                    .foregroundStyle(CCColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)

            if let phone = brief.phone, !phone.isEmpty {
                Button {
                    if let url = telURL(phone) { openURL(url) }
                } label: {
                    Label(phone, systemImage: "phone.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(CCColor.primary)
                .frame(minHeight: 44, alignment: .leading)
                .accessibilityLabel("\(UIText.courtCallA11yPrefix) \(spelledOut(phone))")
                .accessibilityAddTraits(.isButton)
            }

            briefBlock(title: UIText.courtWhatToExpect, body: brief.whatToExpectEs)

            if !brief.whatToBringEs.isEmpty {
                listBlock(icon: "checkmark.circle.fill",
                          tint: CCColor.success,
                          title: UIText.courtWhatToBring,
                          items: brief.whatToBringEs)
            }
            if !brief.whatNotToBringEs.isEmpty {
                listBlock(icon: "xmark.circle.fill",
                          tint: CCColor.urgent,
                          title: UIText.courtWhatNotToBring,
                          items: brief.whatNotToBringEs)
            }

            briefBlock(title: UIText.courtDressCode, body: brief.dressCodeEs)
        }
    }

    private func briefBlock(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: CCSpacing.xs) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(CCColor.ink)
                .accessibilityAddTraits(.isHeader)
            Text(body)
                .font(.body)
                .foregroundStyle(CCColor.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, CCSpacing.xs)
    }

    private func listBlock(icon: String, tint: Color, title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: CCSpacing.xs) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(CCColor.ink)
                .accessibilityAddTraits(.isHeader)
            ForEach(items, id: \.self) { item in
                Label {
                    Text(item)
                        .font(.body)
                        .foregroundStyle(CCColor.ink)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: icon)
                        .foregroundStyle(tint)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.top, CCSpacing.xs)
    }

    private func telURL(_ phone: String) -> URL? {
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        return URL(string: "tel:\(digits)")
    }

    /// Space out digits so VoiceOver reads a phone number digit-by-digit.
    private func spelledOut(_ phone: String) -> String {
        phone.map(String.init).joined(separator: " ")
    }
}
