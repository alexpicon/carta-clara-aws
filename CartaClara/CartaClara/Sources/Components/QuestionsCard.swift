//
//  QuestionsCard.swift
//  Carta Clara
//
//  The "questions for your lawyer" card in the results stack.
//
//  CONTRACT NOTE: the POST /scan response carries no questions array. The
//  questions for the lawyer are part of the Response Preparation Packet
//  (`questions_for_lawyer_es` in POST /scan/packet). So this card is a
//  ROUTING card — it explains the value and sends the user to generate the
//  packet, where the actual (backend-authored) Spanish questions live.
//

import SwiftUI

/// Results-stack card that routes the user to the preparation packet.
struct QuestionsCard: View {
    /// Invoked when the user wants to build the packet.
    let onPrepare: () -> Void

    var body: some View {
        CardContainer(accent: CCColor.primary) {
            CardTitle(icon: "questionmark.circle.fill", text: UIText.questionsCardTitle)

            Text(UIText.questionsCardBody)
                .font(.body)
                .foregroundStyle(CCColor.ink)
                .fixedSize(horizontal: false, vertical: true)

            Button(UIText.questionsCardCTA, action: onPrepare)
                .buttonStyle(CCSecondaryButtonStyle())
                .padding(.top, CCSpacing.xs)
        }
        .accessibilityElement(children: .contain)
    }
}
