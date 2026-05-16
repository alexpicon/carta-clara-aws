//
//  RefusalCounter.swift
//  Carta Clara
//
//  The floating refusal counter — the trust story compressed into one number.
//
//  "The first feature we built was the list of questions we refuse to answer."
//  Every refusal is visible, not hidden (TENETS.md §1, §2). This element
//  floats top-right on the Ask screen, animates when it increments, and opens
//  the refusal log when tapped.
//

import SwiftUI

/// A floating pill showing how many questions the app has refused this
/// session. Tapping opens the refusal log.
struct RefusalCounter: View {
    let count: Int
    let action: () -> Void

    /// Drives the bump animation when the count changes.
    @State private var bumped = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: CCSpacing.xs + 2) {
                Image(systemName: "hand.raised.fill")
                    .font(.subheadline.weight(.bold))
                    .accessibilityHidden(true)
                Text("\(count)")
                    .font(.headline.weight(.bold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .foregroundStyle(.white)
            .padding(.vertical, CCSpacing.sm)
            .padding(.horizontal, CCSpacing.md)
            .frame(minHeight: CCMetrics.touchTarget - 8)
            .background(
                Capsule().fill(count > 0 ? CCColor.urgent : CCColor.inkSecondary)
            )
            .overlay(Capsule().stroke(.white.opacity(0.7), lineWidth: 1.5))
            .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
            .scaleEffect(bumped ? 1.18 : 1.0)
        }
        .buttonStyle(.plain)
        .onChange(of: count) { _, _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                bumped = true
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.18)) {
                bumped = false
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(UIText.refusalCounterA11y): \(count)")
        .accessibilityValue(
            count == 0
            ? UIText.refusalCounterEmptyA11y
            : "\(count) \(count == 1 ? "question refused" : "questions refused")."
        )
        .accessibilityHint(UIText.refusalCounterA11yHint)
        .accessibilityAddTraits(.isButton)
    }
}
