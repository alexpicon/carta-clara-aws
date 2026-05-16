//
//  StateViews.swift
//  Carta Clara
//
//  Reusable loading / error / empty states and small shared chrome.
//
//  Every screen that loads data uses these so the loading, error, and empty
//  experiences are consistent and accessible everywhere.
//

import SwiftUI

/// A centered progress indicator with a calm caption.
struct LoadingView: View {
    var message: String = UIText.loading

    var body: some View {
        VStack(spacing: CCSpacing.md) {
            ProgressView()
                .controlSize(.large)
                .tint(CCColor.primary)
            Text(message)
                .font(.headline)
                .foregroundStyle(CCColor.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(CCSpacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

/// A full-screen error state with an optional retry action.
struct ErrorStateView: View {
    let message: String
    var retryable: Bool = true
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: CCSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(CCColor.caution)
                .accessibilityHidden(true)
            Text(UIText.errorTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(CCColor.ink)
            Text(message)
                .font(.body)
                .foregroundStyle(CCColor.inkSecondary)
                .multilineTextAlignment(.center)
            if retryable, let onRetry {
                Button(UIText.errorRetry, action: onRetry)
                    .buttonStyle(CCPrimaryButtonStyle())
                    .padding(.top, CCSpacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(CCSpacing.xl)
        .accessibilityElement(children: .contain)
    }
}

/// A quiet empty state — a symbol and a sentence.
struct EmptyStateView: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: CCSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(CCColor.inkSecondary.opacity(0.6))
                .accessibilityHidden(true)
            Text(message)
                .font(.body)
                .foregroundStyle(CCColor.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(CCSpacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

/// The "DEMO DOCUMENT" badge. Synthetic data only, always (TENETS.md §6) —
/// this badge is shown whenever the backend flags a demo document so the
/// audience always knows nothing real is on screen.
struct DemoBadge: View {
    var body: some View {
        Text(UIText.demoBadge)
            .font(.caption2.weight(.heavy))
            .tracking(0.5)
            .foregroundStyle(.white)
            .padding(.vertical, CCSpacing.xs)
            .padding(.horizontal, CCSpacing.sm)
            .background(CCColor.inkSecondary)
            .clipShape(Capsule())
            .accessibilityLabel("Documento de demostración. No es un caso real.")
    }
}
