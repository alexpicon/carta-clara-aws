//
//  LanguagePickerView.swift
//  Carta Clara
//
//  Choose the output language for the document analysis.
//
//  Shown AFTER the user confirms a photo and BEFORE the scan call runs, so
//  the backend can produce summary/section/urgency content in the chosen
//  language in a single pass (no second round trip, no wasted tokens).
//
//  The app's UI chrome stays English regardless — this only controls the
//  language of the document content the backend returns.
//

import SwiftUI

struct LanguagePickerView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: CCSpacing.lg) {
            Spacer()

            VStack(spacing: CCSpacing.sm) {
                Image(systemName: "character.bubble")
                    .font(.system(size: 56))
                    .foregroundStyle(CCColor.primary)
                    .accessibilityHidden(true)

                Text("Choose your language")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(CCColor.ink)
                    .multilineTextAlignment(.center)

                Text("Your document will be explained in the language you pick. You can pick another one on your next scan.")
                    .font(.subheadline)
                    .foregroundStyle(CCColor.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CCSpacing.lg)
            }

            Spacer()

            VStack(spacing: CCSpacing.md) {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        pick(language)
                    } label: {
                        Text(language.nativeName)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(language == .english ? AnyButtonStyle(CCPrimaryButtonStyle())
                                                      : AnyButtonStyle(CCSecondaryButtonStyle()))
                    .accessibilityLabel("Explain in \(language.displayName)")
                }
            }
            .padding(.horizontal, CCSpacing.lg)
            .padding(.bottom, CCSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CCColor.background)
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func pick(_ language: AppLanguage) {
        appState.selectedLanguage = language
        appState.path.append(.processing)
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
