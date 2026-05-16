//
//  DesignSystem.swift
//  Carta Clara
//
//  Shared visual language: colors, spacing, radii, and reusable view styles.
//
//  Every value here is judged against the grandma test (TENETS.md §5): high
//  contrast, large touch targets (>= 48pt), and full Dynamic Type support.
//  Colors use semantic names so a future dark-mode pass changes one file.
//

import SwiftUI

// MARK: - Color palette

/// Semantic colors. WCAG-AA contrast against their intended backgrounds.
enum CCColor {
    /// Warm paper background — calmer than stark white.
    static let background = Color(red: 0.98, green: 0.97, blue: 0.95)
    /// Card / sheet surface.
    static let surface = Color.white
    /// Primary text. ~16:1 on surface.
    static let ink = Color(red: 0.11, green: 0.13, blue: 0.16)
    /// Secondary text. ~7:1 on surface.
    static let inkSecondary = Color(red: 0.34, green: 0.37, blue: 0.42)
    /// Trust blue — primary actions, brand.
    static let primary = Color(red: 0.13, green: 0.34, blue: 0.60)
    /// Text on a primary-filled surface.
    static let onPrimary = Color.white
    /// Urgent / deadline accent (deep red, not alarm red).
    static let urgent = Color(red: 0.70, green: 0.18, blue: 0.15)
    /// Scam / caution accent.
    static let caution = Color(red: 0.74, green: 0.42, blue: 0.05)
    /// Reassuring green — "no red flags," success.
    static let success = Color(red: 0.13, green: 0.45, blue: 0.28)
    /// The literal redaction bar color.
    static let redaction = Color(red: 0.07, green: 0.08, blue: 0.10)
    /// Citation chip background.
    static let chip = Color(red: 0.89, green: 0.92, blue: 0.97)
}

// MARK: - Spacing & radii

/// 4pt spacing scale.
enum CCSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

/// Corner radii.
enum CCRadius {
    static let card: CGFloat = 18
    static let control: CGFloat = 14
}

/// Minimum interactive target. Apple HIG floor is 44pt; we use 56 for grandma.
enum CCMetrics {
    static let touchTarget: CGFloat = 56
}

// MARK: - Card container

/// Standard card chrome used by every result card. Children stay focused on
/// content; padding, background, corner, and shadow are centralized here.
struct CardContainer<Content: View>: View {
    /// Optional accent stripe down the leading edge (urgency, scam, etc.).
    private let accent: Color?
    private let content: Content

    /// - Parameter accent: optional leading accent stripe color.
    init(accent: Color? = nil, @ViewBuilder content: () -> Content) {
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 0) {
            if let accent {
                accent
                    .frame(width: 6)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: CCSpacing.sm) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(CCSpacing.md)
        }
        .background(CCColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: CCRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CCRadius.card, style: .continuous)
                .stroke(Color.black.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Card title

/// Consistent card header: an SF Symbol plus a title. The symbol is decorative
/// (accessibilityHidden) — the title carries the meaning for VoiceOver.
struct CardTitle: View {
    let icon: String
    let text: String
    var tint: Color = CCColor.primary

    var body: some View {
        Label {
            Text(text)
                .font(.headline)
                .foregroundStyle(CCColor.ink)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
        }
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Button styles

/// Full-width primary action button. Tall enough for arthritic, one-handed use.
struct CCPrimaryButtonStyle: ButtonStyle {
    var fill: Color = CCColor.primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold))
            .foregroundStyle(CCColor.onPrimary)
            .frame(maxWidth: .infinity, minHeight: CCMetrics.touchTarget)
            .padding(.horizontal, CCSpacing.md)
            .background(fill.opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(RoundedRectangle(cornerRadius: CCRadius.control, style: .continuous))
            .contentShape(Rectangle())
    }
}

/// Secondary (outlined) action button.
struct CCSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold))
            .foregroundStyle(CCColor.primary)
            .frame(maxWidth: .infinity, minHeight: CCMetrics.touchTarget)
            .padding(.horizontal, CCSpacing.md)
            .background(CCColor.primary.opacity(configuration.isPressed ? 0.12 : 0.06))
            .overlay(
                RoundedRectangle(cornerRadius: CCRadius.control, style: .continuous)
                    .stroke(CCColor.primary.opacity(0.5), lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: CCRadius.control, style: .continuous))
            .contentShape(Rectangle())
    }
}
