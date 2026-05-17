//
//  QuestionsCard.swift
//  Carta Clara
//
//  The "questions for your lawyer" card in the results stack.
//
//  CONTRACT NOTE: the POST /scan response carries no questions array. The
//  questions for the lawyer live inside the Response Preparation Packet
//  (`questions_for_lawyer_es` in POST /scan/packet). This card just teases
//  that value — the actual packet is generated via the "Help me respond"
//  bottom action (avoids two buttons that go to the same screen).
//

import SwiftUI

/// Results-stack card that previews the questions-for-lawyer feature.
struct QuestionsCard: View {
    var body: some View {
        CardContainer(accent: CCColor.primary) {
            CardTitle(icon: "questionmark.circle.fill", text: UIText.questionsCardTitle)

            Text(UIText.questionsCardBody)
                .font(.body)
                .foregroundStyle(CCColor.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .contain)
    }
}
