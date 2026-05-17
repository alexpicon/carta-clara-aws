//
//  LegalHelpView.swift
//  Carta Clara
//
//  Free legal-aid clinics — the human at the end of every refusal.
//
//  "A refusal that routes to free legal aid is a feature, not a failure."
//  (TENETS.md §2). Every clinic card has a one-tap call button and a
//  directions button so a 70-year-old can reach a human in one move.
//
//  DATA SOURCE: the three clinics are hard-coded for v1 (RIKU-13) from
//  kb-corpus/seattle_legal_aid.txt — NWIRP, Colectiva Legal del Pueblo, and
//  Refugee Women's Alliance. These are public organization contact details
//  (not legal advice, not PII). The corpus itself carries a verification
//  note; the UI repeats "confirm before you go."
//

import SwiftUI

struct LegalHelpView: View {
    @EnvironmentObject private var appState: AppState

    /// Prefer the legal-aid options the backend returned with the scan; fall
    /// back to the hard-coded Seattle clinics if none are available (e.g. the
    /// user opened this screen before scanning).
    private var clinics: [LegalAidOption] {
        if let fromScan = appState.scanResult?.legalAidOptions, !fromScan.isEmpty {
            return fromScan
        }
        return Self.seattleClinics
    }

    var body: some View {
        ScrollView {
            VStack(spacing: CCSpacing.md) {
                intro
                    .ccAppear()
                ForEach(Array(clinics.enumerated()), id: \.element.id) { offset, clinic in
                    ClinicCard(clinic: clinic)
                        .ccAppear(index: offset + 1)
                }
                verifyNote
                    .ccAppear(index: clinics.count + 1)
            }
            .padding(CCSpacing.md)
        }
        .background(CCGradient.warmPaper)
        .navigationTitle(UIText.legalHelpTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    CCHaptics.light()
                    appState.startFresh()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .accessibilityLabel("Scan another document")
            }
        }
    }

    private var intro: some View {
        Text(UIText.legalHelpIntro)
            .font(.body)
            .foregroundStyle(CCColor.inkSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var verifyNote: some View {
        Label {
            Text(UIText.legalHelpVerifyNote)
                .font(.footnote)
                .foregroundStyle(CCColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "info.circle")
                .foregroundStyle(CCColor.primary)
                .accessibilityHidden(true)
        }
        .padding(CCSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CCColor.chip.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: CCRadius.control))
        .accessibilityElement(children: .combine)
    }

    // MARK: Hard-coded Seattle clinics (kb-corpus/seattle_legal_aid.txt)

    static let seattleClinics: [LegalAidOption] = [
        LegalAidOption(
            name: "Northwest Immigrant Rights Project (NWIRP)",
            phone: "206-587-4009",
            address: "615 Second Avenue, Suite 400, Seattle, WA 98104",
            hours: "Monday to Friday, 9:00 AM–12:00 PM and 1:00 PM–4:30 PM",
            languages: ["Spanish", "interpretation available"],
            free: true
        ),
        LegalAidOption(
            name: "Colectiva Legal del Pueblo",
            phone: "206-931-1514",
            address: "13838 First Avenue S, Burien, WA 98168",
            hours: "Monday, Tuesday, Thursday and Friday, 9:00 AM–5:00 PM",
            languages: ["Spanish"],
            free: true
        ),
        LegalAidOption(
            name: "Refugee Women's Alliance (ReWA)",
            phone: "206-721-0243",
            address: "4008 Martin Luther King Jr. Way S, Seattle, WA 98108",
            hours: "Monday to Friday, office hours (call to confirm the legal clinic)",
            languages: ["Spanish", "and many other languages"],
            free: true
        )
    ]
}

// MARK: - Clinic card

/// One legal-aid clinic with call + directions actions.
private struct ClinicCard: View {
    let clinic: LegalAidOption
    @Environment(\.openURL) private var openURL

    var body: some View {
        // No accent stripe — the "FREE" green pill already carries the meaning.
        // A leading green stripe on every card reads like a "resolved" state,
        // which these invitations-to-call are not.
        CardContainer {
            HStack(alignment: .top) {
                Text(clinic.name)
                    .font(.headline)
                    .foregroundStyle(CCColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                if clinic.free ?? false {
                    Text(UIText.freeBadge)
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(.white)
                        .padding(.vertical, 3)
                        .padding(.horizontal, CCSpacing.sm)
                        .background(CCColor.success)
                        .clipShape(Capsule())
                        .accessibilityLabel("Servicio gratis")
                }
            }

            infoRow(icon: "mappin.circle.fill", text: clinic.address)

            if let hours = clinic.hours, !hours.isEmpty {
                infoRow(icon: "clock.fill", text: "\(UIText.legalHelpHoursLabel): \(hours)")
            }
            if let languages = clinic.languages, !languages.isEmpty {
                infoRow(
                    icon: "globe.americas.fill",
                    text: "\(UIText.legalHelpLanguagesLabel): \(languages.joined(separator: ", "))"
                )
            }

            // Primary action — Call. Full-width green for "this is the move."
            Button {
                CCHaptics.light()
                if let url = telURL(clinic.phone) { openURL(url) }
            } label: {
                Label("\(UIText.callButton)  \(clinic.phone)", systemImage: "phone.fill")
            }
            .buttonStyle(CCPrimaryButtonStyle(fill: CCColor.success))
            .padding(.top, CCSpacing.xs)
            .accessibilityLabel("\(UIText.callButton) a \(clinic.name)")
            .accessibilityHint("Marca \(spelledOut(clinic.phone))")

            // Secondary action — Directions. Pill on the trailing edge so it
            // doesn't compete with Call for attention; matches the
            // "Listen to summary" pill on Results for cross-screen rhyme.
            HStack {
                Spacer()
                Button {
                    CCHaptics.light()
                    if let url = mapsURL(clinic.address) { openURL(url) }
                } label: {
                    Label(UIText.directionsButton, systemImage: "map.fill")
                }
                .buttonStyle(CCInlineButtonStyle())
                .accessibilityHint("Abre el mapa hacia \(clinic.name)")
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func infoRow(icon: String, text: String) -> some View {
        Label {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(CCColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(CCColor.primary)
                .accessibilityHidden(true)
        }
    }

    private func telURL(_ phone: String) -> URL? {
        URL(string: "tel:\(phone.filter { $0.isNumber || $0 == "+" })")
    }

    private func mapsURL(_ address: String) -> URL? {
        let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "http://maps.apple.com/?q=\(encoded)")
    }

    private func spelledOut(_ phone: String) -> String {
        phone.map(String.init).joined(separator: " ")
    }
}
