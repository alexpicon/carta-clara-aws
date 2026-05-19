//
//  CartaClaraApp.swift
//  Carta Clara
//
//  SwiftUI app entry point and navigation root.
//
//  Carta Clara turns a frightening English document into a plain summary
//  in Spanish or English, a deadline, a scam check, and a path to a free
//  lawyer — without ever giving legal advice. The UI is English-default;
//  the output language is chosen by the user at the scan-time picker.
//  See docs/PRESS_RELEASE.md and docs/TENETS.md.
//
//  Navigation is a single NavigationStack driven by `AppState.path`. The
//  splash screen is the root; every other screen is a `Route` destination.
//

import SwiftUI

@main
struct CartaClaraApp: App {
    /// One AppState for the whole app lifetime — owns navigation, session,
    /// the scan result, and the refusal counter.
    @StateObject private var appState = AppState()
    /// Shared on-device TTS — powers the per-card speaker buttons. Lives
    /// at the app root so only one card plays at a time across screens.
    @StateObject private var speech = SpeechSynthesizer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(speech)
                // Light scheme only for v1: every color in DesignSystem is
                // tuned for WCAG-AA contrast on the light background. A dark
                // palette is a deliberate follow-up, not a half-done feature.
                .preferredColorScheme(.light)
        }
    }
}

/// The navigation root. Hosts the stack and maps every `Route` to its screen.
struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack(path: $appState.path) {
            SplashView()
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
        }
        .tint(CCColor.primary)
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .cameraTips:
            CameraTipsView()
        case .camera:
            CameraCaptureView()
        case .languagePicker:
            LanguagePickerView()
        case .processing:
            RedactionAnimationView()
        case .results:
            ResultsView()
        case .ask:
            AskChatView()
        case .refusalLog:
            RefusalLogView()
        case .packet:
            ResponsePacketView()
        case .legalHelp:
            LegalHelpView()
        }
    }
}
