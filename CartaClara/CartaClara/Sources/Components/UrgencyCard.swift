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

    private var accent: Color {
        urgency.isUrgent ? CCColor.urgent : CCColor.inkSecondary
    }

    var body: some View {
        CardContainer(accent: accent) {
            CardTitle(
                icon: urgency.isUrgent ? "calendar.badge.exclamationmark" : "calendar",
                text: "Fecha importante",
                tint: accent
            )

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
        var parts = ["Fecha importante."]
        if let label = urgency.deadlineLabelEs, !label.isEmpty { parts.append(label) }
        if let note = urgency.verificationNoteEs, !note.isEmpty { parts.append(note) }
        return parts.joined(separator: " ")
    }
}
