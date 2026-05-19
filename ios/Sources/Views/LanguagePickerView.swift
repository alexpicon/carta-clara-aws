//
//  LanguagePickerView.swift
//  Carta Clara
//
//  Choose the output language for the document analysis.
//
//  Shown FIRST after the splash — before the camera tips, before the camera.
//  Picking here means the rest of the flow (tips screen, redaction animation,
//  result cards, refusal text) all render in the chosen language. Picking
//  language *before* the camera matters for accessibility: a Spanish-only
//  user needs to see the camera tips in Spanish, not English.
//
//  The app's pre-pick chrome stays English (this screen, splash) — only
//  what comes AFTER the pick respects the choice.
//

import SwiftUI

struct LanguagePickerView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: CCSpacing.lg) {
            Spacer()

            VStack(spacing: CCSpacing.sm) {
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(CCColor.primary)
                    .accessibilityHidden(true)

                Text("Choose your language")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(CCColor.ink)
                    .multilineTextAlignment(.center)

                Text("Pick the language for everything that comes next — tips, your document's summary, and answers. You can pick a different one on your next scan.")
                    .font(.subheadline)
                    .foregroundStyle(CCColor.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CCSpacing.lg)
            }
            .ccAppear()

            Spacer()

            VStack(spacing: CCSpacing.md) {
                ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element) { offset, language in
                    Button {
                        pick(language)
                    } label: {
                        Text(language.nativeName)
                            .frame(maxWidth: .infinity)
                    }
                    // Español is the primary (filled) button because Carta Clara
                    // is built for Spanish-speaking users first. English is the
                    // available alternative, not the default suggestion.
                    .buttonStyle(language == .spanish ? AnyButtonStyle(CCPrimaryButtonStyle())
                                                      : AnyButtonStyle(CCSecondaryButtonStyle()))
                    .accessibilityLabel("Explain in \(language.displayName)")
                    .ccAppear(index: offset + 2)
                }
            }
            .padding(.horizontal, CCSpacing.lg)
            .padding(.bottom, CCSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CCGradient.warmPaper)
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func pick(_ language: AppLanguage) {
        CCHaptics.light()
        appState.selectedLanguage = language
        appState.path.append(.cameraTips)
    }
}

/// Type-erased button style so the ForEach can swap styles by language without
/// the compiler bristling at heterogeneous return types.
private struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        self._makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}
