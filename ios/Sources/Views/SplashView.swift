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

    var body: some View {
        ZStack {
            CCColor.background.ignoresSafeArea()

            VStack(spacing: CCSpacing.lg) {
                Spacer()

                // Wordmark
                VStack(spacing: CCSpacing.sm) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 72, weight: .light))
                        .foregroundStyle(CCColor.primary)
                        .accessibilityHidden(true)
                    Text(UIText.appName)
                        .font(.system(size: 44, weight: .bold, design: .serif))
                        .foregroundStyle(CCColor.ink)
                    Text(UIText.tagline)
                        .font(.title3)
                        .foregroundStyle(CCColor.inkSecondary)
                        .multilineTextAlignment(.center)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(UIText.appName). \(UIText.tagline)")
                .accessibilityAddTraits(.isHeader)

                Spacer()

                if !appState.isBackendConfigured {
                    notConfiguredNotice
                }

                VStack(spacing: CCSpacing.md) {
                    Button(UIText.getStarted) {
                        appState.startNewScan()
                        appState.path.append(.camera)
                    }
                    .buttonStyle(CCPrimaryButtonStyle())
                    .accessibilityHint(UIText.splashCameraHint)

                    Button {
                        showDisclaimer = true
                    } label: {
                        Label(UIText.disclaimerButton, systemImage: "info.circle")
                    }
                    .buttonStyle(CCSecondaryButtonStyle())

                    // Demo safety net (RIKU-17): bypasses the camera and runs
                    // the scan pipeline on a bundled synthetic NTA. Kept small
                    // and low-key so everyday users are not confused by it.
                    Button {
                        if !appState.loadDemoDocument() {
                            showDemoMissingAlert = true
                        }
                    } label: {
                        Label(UIText.tryDemoButton, systemImage: "doc.badge.ellipsis")
                            .font(.footnote)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(CCColor.inkSecondary)
                    .frame(minHeight: 44)
                    .accessibilityHint(UIText.splashDemoHint)
                }
                .padding(.horizontal, CCSpacing.lg)
                .padding(.bottom, CCSpacing.xl)
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
            .background(CCColor.background)
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
