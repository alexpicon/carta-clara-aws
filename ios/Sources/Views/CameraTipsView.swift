//
//  CameraTipsView.swift
//  Carta Clara
//
//  A short pre-capture primer shown between Splash and the live camera. The
//  user gets 4 concrete tips (light, framing, steadiness, background) so the
//  Textract OCR has the best chance of reading the document on the first try.
//  The screen is intentionally low-friction — one Continue button, no
//  required interaction beyond reading.
//

import SwiftUI

struct CameraTipsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: CCSpacing.lg) {
                    header
                    tipsCard
                }
                .padding(.horizontal, CCSpacing.lg)
                .padding(.top, CCSpacing.lg)
            }

            continueButton
        }
        .background(CCGradient.warmPaper)
        .navigationTitle(UIText.cameraTipsTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: CCSpacing.sm) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 44))
                .foregroundStyle(CCColor.primary)
                .accessibilityHidden(true)

            Text(UIText.cameraTipsHeading)
                .font(.title2.weight(.bold))
                .foregroundStyle(CCColor.ink)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text(UIText.cameraTipsSubheading)
                .font(.subheadline)
                .foregroundStyle(CCColor.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, CCSpacing.md)
    }

    // MARK: Tips card

    private var tipsCard: some View {
        CardContainer {
            tipRow(icon: "sun.max.fill",
                   tint: CCColor.caution,
                   title: UIText.cameraTipLightTitle,
                   body: UIText.cameraTipLightBody)

            Divider()

            tipRow(icon: "viewfinder",
                   tint: CCColor.primary,
                   title: UIText.cameraTipFrameTitle,
                   body: UIText.cameraTipFrameBody)

            Divider()

            tipRow(icon: "hand.raised.fill",
                   tint: CCColor.success,
                   title: UIText.cameraTipSteadyTitle,
                   body: UIText.cameraTipSteadyBody)

            Divider()

            tipRow(icon: "sun.haze.fill",
                   tint: CCColor.caution,
                   title: UIText.cameraTipBackgroundTitle,
                   body: UIText.cameraTipBackgroundBody)
        }
    }

    private func tipRow(icon: String, tint: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: CCSpacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 32, alignment: .center)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(CCColor.ink)
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(CCColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, CCSpacing.xs)
        .accessibilityElement(children: .combine)
    }

    // MARK: Continue button

    private var continueButton: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                CCHaptics.light()
                appState.path.append(.camera)
            } label: {
                Label(UIText.cameraTipsContinue, systemImage: "camera.fill")
            }
            .buttonStyle(CCPrimaryButtonStyle())
            .padding(.horizontal, CCSpacing.lg)
            .padding(.vertical, CCSpacing.md)
        }
        .background(CCColor.surface)
    }
}
