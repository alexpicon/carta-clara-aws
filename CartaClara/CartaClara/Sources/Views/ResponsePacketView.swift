//
//  ResponsePacketView.swift
//  Carta Clara
//
//  The Response Preparation Packet — the artifact moment (DEMO_SCRIPT 2:00).
//
//  "This is what we hand the grandmother. Not a response to USCIS — we will
//  never write that." The packet is what she brings to a free legal-aid
//  appointment. The cover sheet says so in big text.
//
//  All packet copy is Spanish authored by the backend (POST /scan/packet);
//  this screen only lays it out and lets the user share / print it.
//

import SwiftUI

struct ResponsePacketView: View {
    @EnvironmentObject private var appState: AppState

    @State private var state: LoadState = .idle
    @State private var result: PacketResult?
    @State private var showShareSheet = false
    /// Indexes of "Documents to gather" rows the user has marked off. Held
    /// in this view (not AppState) — a checklist resets when the user
    /// navigates away from the packet. No persistence (TENETS §7).
    @State private var checkedDocuments: Set<Int> = []

    var body: some View {
        Group {
            switch state {
            case .idle, .loading:
                LoadingView(message: UIText.packetGenerating)
            case .failed(let message, let retryable):
                ErrorStateView(
                    message: message,
                    retryable: retryable,
                    onRetry: { Task { await load() } }
                )
            case .loaded:
                if let result {
                    packetContent(result)
                } else {
                    ErrorStateView(message: UIText.packetError, retryable: true) {
                        Task { await load() }
                    }
                }
            }
        }
        .background(CCGradient.warmPaper)
        .navigationTitle(UIText.packetTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    CCHaptics.light()
                    appState.startFresh()
                } label: {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.title3)
                }
                .accessibilityLabel(UIText.restartScan)
            }
        }
        .task {
            if case .idle = state { await load() }
        }
        .sheet(isPresented: $showShareSheet) {
            if let result {
                ShareSheet(items: shareItems(for: result))
            }
        }
    }

    // MARK: Content

    private func packetContent(_ result: PacketResult) -> some View {
        let packet = result.packet
        return ScrollView {
            VStack(alignment: .leading, spacing: CCSpacing.md) {
                // Title
                Text(packet.titleEs)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(CCColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .ccAppear()

                section(UIText.packetWhatItSays, icon: "doc.text.fill") {
                    Text(packet.whatThisSaysEs)
                        .font(.body)
                        .foregroundStyle(CCColor.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .ccAppear(index: 1)

                if let deadline = packet.yourDeadline,
                   let label = deadline.labelEs, !label.isEmpty {
                    section(UIText.packetDeadline, icon: "calendar.badge.exclamationmark",
                            tint: CCColor.urgent) {
                        Text(label)
                            .font(.headline)
                            .foregroundStyle(CCColor.urgent)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .ccAppear(index: 2)
                }

                section(UIText.packetDocuments, icon: "checkmark.circle.fill") {
                    checklistRows(packet.documentsToGatherEs)
                }
                .ccAppear(index: 3)

                // The "extension request template" section was removed:
                // providing such a template (even with a disclaimer) implies a
                // recommendation that the user request more time, which is too
                // close to legal strategy advice (TENETS §3). The user gets the
                // questions list + phone script + cover sheet instead, all of
                // which route to a free legal-aid attorney who decides whether
                // an extension is appropriate.

                section(UIText.packetPhoneScript, icon: "phone.bubble.fill") {
                    Text(packet.legalAidPhoneScriptEs)
                        .font(.body)
                        .italic()
                        .foregroundStyle(CCColor.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .ccAppear(index: 4)

                section(UIText.packetQuestions, icon: "questionmark.circle.fill") {
                    bulletList(packet.questionsForLawyerEs, symbol: "circle")
                }
                .ccAppear(index: 5)

                coverSheet(packet.coverSheetEs)
                    .ccAppear(index: 6)

                shareButton
                    .ccAppear(index: 7)
            }
            .padding(CCSpacing.md)
        }
    }

    /// A titled packet section in card chrome.
    private func section<Content: View>(
        _ title: String,
        icon: String,
        tint: Color = CCColor.primary,
        @ViewBuilder content: () -> Content
    ) -> some View {
        CardContainer {
            CardTitle(icon: icon, text: title, tint: tint)
            content()
        }
    }

    private func bulletList(_ items: [String], symbol: String) -> some View {
        VStack(alignment: .leading, spacing: CCSpacing.sm) {
            ForEach(items, id: \.self) { item in
                Label {
                    Text(item)
                        .font(.body)
                        .foregroundStyle(CCColor.ink)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: symbol)
                        .foregroundStyle(CCColor.primary)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    /// Interactive checklist for "Documents to gather". Each row toggles
    /// between empty square and filled checkmark on tap; selection state
    /// lives in the view and resets on navigate-away (TENETS §7 — nothing
    /// the user touches is persisted to disk).
    private func checklistRows(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: CCSpacing.sm) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                let isChecked = checkedDocuments.contains(index)
                Button {
                    CCHaptics.soft()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if isChecked {
                            checkedDocuments.remove(index)
                        } else {
                            checkedDocuments.insert(index)
                        }
                    }
                } label: {
                    Label {
                        Text(item)
                            .font(.body)
                            .foregroundStyle(isChecked ? CCColor.inkSecondary : CCColor.ink)
                            .strikethrough(isChecked, color: CCColor.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } icon: {
                        Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                            .foregroundStyle(isChecked ? CCColor.success : CCColor.primary)
                            .font(.title3)
                            .accessibilityHidden(true)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44, alignment: .leading)
                .accessibilityLabel(item)
                .accessibilityValue(isChecked ? "checked" : "unchecked")
                .accessibilityAddTraits(isChecked ? [.isButton, .isSelected] : .isButton)
                .accessibilityHint("Tap to toggle.")
            }
        }
    }

    /// Renders the extension-request template as a clean letter, NOT a code
    /// block. The backend produces plain text with `\n\n` paragraph breaks;
    /// we split on those and render each paragraph with normal body type so
    /// it reads like a letter the user would actually fill out.
    private func letterBlock(_ text: String) -> some View {
        let paragraphs = text
            .split(separator: "\n\n", omittingEmptySubsequences: true)
            .map(String.init)
        return VStack(alignment: .leading, spacing: CCSpacing.sm) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.body)
                    .foregroundStyle(CCColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// The cover sheet — the packet's hero. Subtle internal gradient and a
    /// hairline inner stroke read like a sealed envelope, distinguishing it
    /// from the white card chrome above.
    private func coverSheet(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: CCSpacing.sm) {
            Label(UIText.packetCoverSheet, systemImage: "bookmark.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(CCColor.onPrimary.opacity(0.85))
            Text(text)
                .font(.title3.weight(.semibold))
                .foregroundStyle(CCColor.onPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(CCSpacing.md)
        .background(
            LinearGradient(
                colors: [CCColor.primary, CCColor.primary.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: CCRadius.card, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: CCRadius.card, style: .continuous))
        .shadow(color: CCColor.primary.opacity(0.18), radius: 12, x: 0, y: 4)
        .accessibilityElement(children: .combine)
    }

    private var shareButton: some View {
        Button {
            CCHaptics.success()
            showShareSheet = true
        } label: {
            Label(UIText.packetShare, systemImage: "square.and.arrow.up")
        }
        .buttonStyle(CCPrimaryButtonStyle())
        .padding(.top, CCSpacing.sm)
        .accessibilityLabel(UIText.packetShareA11y)
        .accessibilityHint(UIText.packetShareA11yHint)
    }

    // MARK: Loading

    private func load() async {
        // Fast path: AppState.prefetchPacket already kicked off a /scan/packet
        // call when the scan landed. If it finished, render instantly.
        if let cached = appState.cachedPacket {
            result = cached
            state = .loaded
            return
        }
        guard let documentId = appState.documentId else {
            state = .failed(message: UIText.errorGeneric, retryable: false)
            return
        }
        state = .loading
        do {
            let packet = try await appState.api.packet(
                sessionId: appState.sessionId,
                documentId: documentId,
                extraction: appState.scanResult?.extraction,
                summaryEs: appState.scanResult?.summaryEs,
                summaryEn: appState.scanResult?.summaryEn,
                language: appState.selectedLanguage
            )
            result = packet
            state = .loaded
        } catch let error as APIError {
            state = .failed(
                message: AppState.userMessage(for: error),
                retryable: error.isRetryable
            )
        } catch {
            state = .failed(message: UIText.packetError, retryable: true)
        }
    }

    // MARK: Share

    /// What to hand the share sheet. A freshly rendered local PDF is preferred:
    /// it works offline and is demo-safe (no dependency on a backend render).
    /// Falls back to the backend PDF, then to plain text — so the share button
    /// always produces *something* printable.
    @MainActor
    private func shareItems(for result: PacketResult) -> [Any] {
        if let localPDF = PacketPDF.render(packet: result.packet) {
            return [localPDF]
        }
        if let backend = result.pdfUrl, let url = URL(string: backend) {
            return [url]
        }
        return [Self.plainText(from: result.packet)]
    }

    /// Render the packet as a printable plain-text document.
    static func plainText(from packet: PreparationPacket) -> String {
        var lines: [String] = []
        lines.append(packet.titleEs.uppercased())
        lines.append(String(repeating: "=", count: 40))
        lines.append("")
        lines.append("— \(UIText.packetWhatItSays) —")
        lines.append(packet.whatThisSaysEs)
        lines.append("")
        if let deadline = packet.yourDeadline, let label = deadline.labelEs {
            lines.append("— \(UIText.packetDeadline) —")
            lines.append(label)
            lines.append("")
        }
        lines.append("— \(UIText.packetDocuments) —")
        for item in packet.documentsToGatherEs { lines.append("[ ] \(item)") }
        lines.append("")
        // Extension Request template removed — implied legal-strategy advice.
        lines.append("— \(UIText.packetPhoneScript) —")
        lines.append(packet.legalAidPhoneScriptEs)
        lines.append("")
        lines.append("— \(UIText.packetQuestions) —")
        for item in packet.questionsForLawyerEs { lines.append("• \(item)") }
        lines.append("")
        lines.append(String(repeating: "=", count: 40))
        lines.append(packet.coverSheetEs)
        return lines.joined(separator: "\n")
    }
}
