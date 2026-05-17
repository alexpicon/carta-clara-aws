//
//  RedactionAnimationView.swift
//  Carta Clara
//
//  The visible PII-redaction animation.
//
//  "Before anything reaches the cloud, we redact... You're watching us do it
//  now." (DEMO_SCRIPT 0:25). The redaction is deliberately a bit slow and
//  pedagogical so the audience SEES it happen — the redaction being visible,
//  not hidden in a privacy policy, IS the trust story (TENETS.md §1).
//
//  This screen also runs the /scan request in the background. When both the
//  animation and the scan finish, it advances to the results.
//
//  IMPORTANT: no PII — real or synthetic — is ever displayed. Each row shows
//  a field CATEGORY label and a neutral placeholder bar that gets masked.
//

import SwiftUI

struct RedactionAnimationView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Indices of field rows that have been masked so far.
    @State private var maskedRows: Set<Int> = []
    /// High-level screen phase.
    @State private var phase: Phase = .redacting
    @State private var started = false

    private enum Phase { case redacting, processing, failed }

    private var fields: [String] { UIText.redactionFields }

    var body: some View {
        ZStack {
            CCGradient.warmPaper.ignoresSafeArea()

            switch phase {
            case .redacting, .processing:
                content
            case .failed:
                ErrorStateView(
                    message: scanErrorMessage,
                    retryable: scanRetryable,
                    onRetry: { Task { await retry() } }
                )
            }
        }
        .navigationTitle(UIText.redactionTitle)
        .navigationBarTitleDisplayMode(.inline)
        // Lock navigation while work is in flight; let the user back out to the
        // camera if the scan failed.
        .navigationBarBackButtonHidden(phase != .failed)
        .task {
            guard !started else { return }
            started = true
            await runPipeline()
        }
    }

    // MARK: Content

    private var content: some View {
        VStack(spacing: CCSpacing.lg) {
            Spacer()

            VStack(spacing: CCSpacing.xs) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(CCColor.primary)
                    .symbolEffect(.pulse, options: .repeating, isActive: !allMasked)
                    .accessibilityHidden(true)
                Text(allMasked ? UIText.redactionDone : UIText.redactionTitle)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(CCColor.ink)
                    .multilineTextAlignment(.center)
                Text(UIText.redactionCaption)
                    .font(.subheadline)
                    .foregroundStyle(CCColor.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(UIText.redactionTitle). \(UIText.redactionCaption)")

            // The mock document being redacted.
            VStack(spacing: CCSpacing.sm) {
                ForEach(Array(fields.enumerated()), id: \.offset) { index, label in
                    redactionRow(label: label, masked: maskedRows.contains(index))
                }
            }
            .padding(CCSpacing.md)
            .background(CCColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: CCRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CCRadius.card)
                    .stroke(Color.black.opacity(0.07), lineWidth: 1)
            )
            .padding(.horizontal, CCSpacing.lg)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                allMasked
                ? UIText.redactionCompleteA11y
                : UIText.redactionInProgressA11y
            )

            if phase == .processing {
                PulsingProcessingLabel()
                    .accessibilityAddTraits(.updatesFrequently)
            }

            Spacer()
        }
    }

    /// One field row: a category label and a placeholder that gets masked.
    private func redactionRow(label: String, masked: Bool) -> some View {
        HStack(spacing: CCSpacing.sm) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(CCColor.inkSecondary)
                .frame(width: 130, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            ZStack(alignment: .leading) {
                // Neutral placeholder — never a real or synthetic value.
                RoundedRectangle(cornerRadius: 5)
                    .fill(CCColor.chip)
                    .frame(height: 22)

                if masked {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(CCColor.redaction)
                        .frame(height: 22)
                        .overlay(
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                                Text(UIText.redactedTag)
                                    .font(.caption2.weight(.heavy))
                            }
                            .foregroundStyle(.white)
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 1.0, anchor: .leading).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
        }
    }

    // MARK: Pipeline

    private var allMasked: Bool { maskedRows.count == fields.count }

    /// Run the redaction animation and the /scan request, then advance.
    private func runPipeline() async {
        // Start the network call immediately — it runs while the animation plays.
        async let scan: Void = appState.performScan()

        // Play the staggered masking animation.
        for index in fields.indices {
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 220 : 290))
            if reduceMotion {
                maskedRows.insert(index)
            } else {
                withAnimation(.easeInOut(duration: 0.4)) {
                    _ = maskedRows.insert(index)
                }
            }
        }

        try? await Task.sleep(for: .milliseconds(350))
        UIAccessibility.post(notification: .announcement,
                             argument: UIText.redactionA11yAnnouncement)
        CCHaptics.success()

        withAnimation { phase = .processing }

        // Wait for the scan to finish (it may already be done).
        await scan
        finish()
    }

    /// Inspect the scan result and either advance to results or show an error.
    private func finish() {
        switch appState.scanState {
        case .loaded:
            advanceToResults()
        case .failed:
            withAnimation { phase = .failed }
        case .idle, .loading:
            // Should not happen — performScan always resolves to loaded/failed.
            withAnimation { phase = .failed }
        }
    }

    /// Replace `.processing` on the path with `.results` so Back skips it.
    private func advanceToResults() {
        if let last = appState.path.indices.last, appState.path[last] == .processing {
            appState.path[last] = .results
        } else {
            appState.path.append(.results)
        }
    }

    private func retry() async {
        withAnimation { phase = .processing }
        await appState.performScan()
        finish()
    }

    private var scanErrorMessage: String {
        if case let .failed(message, _) = appState.scanState { return message }
        return UIText.errorGeneric
    }

    private var scanRetryable: Bool {
        if case let .failed(_, retryable) = appState.scanState { return retryable }
        return true
    }
}

// MARK: - Pulsing processing label

/// Animated "Reading the document…" label. The sparkle icon pulses via SF
/// Symbol effect; the text fades in-and-out subtly so the screen visibly
/// "breathes" while the network call is in flight. Stops automatically when
/// the view disappears.
private struct PulsingProcessingLabel: View {
    @State private var pulse = false

    var body: some View {
        Label(UIText.processing, systemImage: "sparkles")
            .font(.headline)
            .foregroundStyle(CCColor.inkSecondary)
            .symbolEffect(.pulse, options: .repeating)
            .opacity(pulse ? 0.55 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}
