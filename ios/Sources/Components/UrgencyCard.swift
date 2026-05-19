//
//  UrgencyCard.swift
//  Carta Clara
//
//  The deadline / urgency card.
//
//  Shows what is urgent and when, plus the instruction to verify the date
//  with the court directly. Information, not advice (TENETS.md §3): we state
//  the deadline the document gives and tell the user to confirm it — we never
//  tell her what to do about it.
//

import SwiftUI

/// Deadline banner. Renders with an urgent accent when `urgency.isUrgent`.
struct UrgencyCard: View {
    let urgency: Urgency
    var language: AppLanguage = .english

    private var accent: Color {
        urgency.isUrgent ? CCColor.urgent : CCColor.inkSecondary
    }

    /// Concatenated read-aloud text — label + verification note.
    private var ttsText: String {
        [urgency.deadlineLabelEs, urgency.verificationNoteEs]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ". ")
    }

    var body: some View {
        CardContainer(accent: accent) {
            HStack(alignment: .firstTextBaseline) {
                CardTitle(
                    icon: urgency.isUrgent ? "calendar.badge.exclamationmark" : "calendar",
                    text: UIText.urgencyCardTitle,
                    tint: accent
                )
                Spacer()
                if !ttsText.isEmpty {
                    CardTTSButton(id: "urgency", text: ttsText, language: language)
                }
            }

            if let label = urgency.deadlineLabelEs, !label.isEmpty {
                Text(label)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(urgency.isUrgent ? CCColor.urgent : CCColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let note = urgency.verificationNoteEs, !note.isEmpty {
                Label {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(CCColor.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(CCColor.primary)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = ["\(UIText.urgencyCardTitle)."]
        if let label = urgency.deadlineLabelEs, !label.isEmpty { parts.append(label) }
        if let note = urgency.verificationNoteEs, !note.isEmpty { parts.append(note) }
        return parts.joined(separator: " ")
    }
}
