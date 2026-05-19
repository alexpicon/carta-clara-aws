//
//  SplashView.swift
//  Carta Clara
//
//  The launch screen: wordmark, tagline, the "what this app does not do"
//  disclaimer, and the single large call to action.
//
//  Trust before features (TENETS.md §1): the disclaimer is reachable before
//  the user does anything. No account, no signup, no email field — one
//  button to begin (Press Release: "How can a 70-year-old grandmother use
//  this? One-handed.").
//

import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showDisclaimer = false
    @State private var showDemoMissingAlert = false
    @State private var wordmarkVisible = false
    @State private var ctasVisible = false

    var body: some View {
        ZStack {
            CCGradient.warmPaper.ignoresSafeArea()

            VStack(spacing: CCSpacing.lg) {
                Spacer()

                // Wordmark + tagline with subtle entrance animation
                VStack(spacing: CCSpacing.md) {
                    // Logo: an open envelope (the letter being read /
                    // understood — exactly what the app does). Gradient fill
                    // + a soft tinted halo makes it feel like a brand mark
                    // instead of a system placeholder symbol.
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [CCColor.primary.opacity(0.18), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                        Image(systemName: "envelope.open.fill")
                            .font(.system(size: 76, weight: .regular))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [CCColor.primary, CCColor.primary.opacity(0.78)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: CCColor.primary.opacity(0.30), radius: 14, x: 0, y: 8)
                    }
                    .accessibilityHidden(true)

                    Text(UIText.appName)
                        .font(.system(size: 46, weight: .bold, design: .serif))
                        .foregroundStyle(CCColor.ink)
                        .tracking(-0.5)
                    Text(UIText.tagline)
                        .font(.title3)
                        .foregroundStyle(CCColor.inkSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(wordmarkVisible ? 1 : 0)
                .scaleEffect(wordmarkVisible ? 1 : 0.96)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(UIText.appName). \(UIText.tagline)")
                .accessibilityAddTraits(.isHeader)

                Spacer()

                if !appState.isBackendConfigured {
                    notConfiguredNotice
                }

                VStack(spacing: CCSpacing.md) {
                    Button(UIText.getStarted) {
                        CCHaptics.light()
                        appState.startNewScan()
                        appState.path.append(.languagePicker)
                    }
                    .buttonStyle(CCPrimaryButtonStyle())
                    .accessibilityHint(UIText.splashCameraHint)

                    Button {
                        showDisclaimer = true
                    } label: {
                        Label(UIText.disclaimerButton, systemImage: "info.circle")
                    }
                    .buttonStyle(CCSecondaryButtonStyle())
                }
                .padding(.horizontal, CCSpacing.lg)
                .padding(.bottom, CCSpacing.xl)
                .opacity(ctasVisible ? 1 : 0)
                .offset(y: ctasVisible ? 0 : 12)
            }
        }
        .onAppear {
            // Wordmark eases in first; CTAs follow a beat later so the eye
            // lands on the brand before the buttons.
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85)) {
                wordmarkVisible = true
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85).delay(0.18)) {
                ctasVisible = true
            }
        }
        .sheet(isPresented: $showDisclaimer) {
            DisclaimerSheet()
        }
        .alert(UIText.demoDocMissingTitle, isPresented: $showDemoMissingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(UIText.demoDocMissingBody)
        }
    }

    private var notConfiguredNotice: some View {
        Text(UIText.errorNotConfigured)
            .font(.footnote)
            .foregroundStyle(CCColor.caution)
            .multilineTextAlignment(.center)
            .padding(CCSpacing.sm)
            .frame(maxWidth: .infinity)
            .background(CCColor.caution.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: CCRadius.control))
            .padding(.horizontal, CCSpacing.lg)
            .accessibilityLabel(UIText.errorNotConfigured)
    }
}

/// The "Information, not legal advice" disclaimer, shown as a sheet.
struct DisclaimerSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CCSpacing.md) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(CCColor.primary)
                        .accessibilityHidden(true)

                    Text(UIText.disclaimerTitle)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(CCColor.ink)
                        .accessibilityAddTraits(.isHeader)

                    Text(UIText.disclaimerBody)
                        .font(.body)
                        .foregroundStyle(CCColor.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(CCSpacing.lg)
            }
            .background(CCGradient.warmPaper)
            .safeAreaInset(edge: .bottom) {
                Button(UIText.disclaimerClose) { dismiss() }
                    .buttonStyle(CCPrimaryButtonStyle())
                    .padding(CCSpacing.lg)
                    .background(CCColor.background)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
