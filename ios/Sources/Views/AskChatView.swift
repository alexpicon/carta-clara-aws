//
//  AskChatView.swift
//  Carta Clara
//
//  The "Ask About This Document" chat surface.
//
//  Voice is the PRIMARY input (push-to-talk mic button) with a text field as
//  the secondary fallback — the grandma test assumes voice is easier
//  (Press Release). The refusal counter floats top-right and visibly ticks up
//  whenever an answer is refused (DEMO_SCRIPT 0:55 — the refusal moment).
//
//  Refuse before answering (TENETS.md §2): a refused answer is rendered
//  distinctly and always routes to free legal aid.
//

import SwiftUI

// MARK: - Chat message model (UI-local, not a contract type)

/// One bubble in the chat. This is presentation state, not an API shape.
struct ChatMessage: Identifiable {
    enum Role { case user, assistant }

    let id = UUID()
    let role: Role
    var text: String
    var isRefusal = false
    var citations: [Citation] = []
    var audioURL: String?
    /// True for a voice question still showing its placeholder.
    var awaitingTranscription = false
}

// MARK: - Ask screen

struct AskChatView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var recorder = AudioRecorder()
    @StateObject private var answerAudio = AudioPlayback()

    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isSending = false
    @State private var sendErrorMessage: String?
    @State private var showMicDeniedAlert = false
    @FocusState private var inputFocused: Bool

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            transcript
            Divider()
            inputBar
        }
        .background(CCGradient.warmPaper)
        .navigationTitle(UIText.askTitle)
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
        .overlay(alignment: .topTrailing) {
            RefusalCounter(count: appState.refusalCount) {
                appState.path.append(.refusalLog)
            }
            .padding(.trailing, CCSpacing.md)
            .padding(.top, CCSpacing.sm)
        }
        .onDisappear { answerAudio.stop() }
        .alert(UIText.micPermissionDeniedTitle, isPresented: $showMicDeniedAlert) {
            Button(UIText.openSettings) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(UIText.micPermissionDeniedBody)
        }
    }

    // MARK: Transcript

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: CCSpacing.md) {
                    if messages.isEmpty {
                        EmptyStateView(
                            icon: "bubble.left.and.bubble.right",
                            message: UIText.askEmptyState
                        )
                        .padding(.top, CCSpacing.xl)
                    }
                    ForEach(messages) { message in
                        messageBubble(message).id(message.id)
                    }
                    if isSending {
                        thinkingBubble.id("thinking")
                    }
                }
                .padding(CCSpacing.md)
                // Room for the floating refusal counter.
                .padding(.top, CCSpacing.xl)
            }
            .onChange(of: messages.count) { _, _ in
                scrollToEnd(proxy)
            }
            .onChange(of: isSending) { _, _ in
                scrollToEnd(proxy)
            }
        }
    }

    private func scrollToEnd(_ proxy: ScrollViewProxy) {
        withAnimation {
            if isSending {
                proxy.scrollTo("thinking", anchor: .bottom)
            } else if let last = messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    @ViewBuilder
    private func messageBubble(_ message: ChatMessage) -> some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: CCSpacing.xl)
                userBubble(message)
            }
        case .assistant:
            HStack {
                assistantBubble(message)
                Spacer(minLength: CCSpacing.xl)
            }
        }
    }

    private func userBubble(_ message: ChatMessage) -> some View {
        Label {
            Text(message.text)
                .font(.body)
        } icon: {
            if message.awaitingTranscription {
                Image(systemName: "waveform")
            }
        }
        .foregroundStyle(CCColor.onPrimary)
        .padding(CCSpacing.md)
        .background(CCColor.primary)
        .clipShape(RoundedRectangle(cornerRadius: CCRadius.card))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(UIText.askYou): \(message.text)")
    }

    private func assistantBubble(_ message: ChatMessage) -> some View {
        VStack(alignment: .leading, spacing: CCSpacing.sm) {
            if message.isRefusal {
                Label(UIText.askRefusalLabel, systemImage: "hand.raised.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(CCColor.urgent)
                    .padding(.vertical, 6)
                    .padding(.horizontal, CCSpacing.sm)
                    .background(CCColor.urgent.opacity(0.12))
                    .clipShape(Capsule())
                    .accessibilityAddTraits(.isHeader)
            }

            Text(message.text)
                .font(.body)
                .foregroundStyle(CCColor.ink)
                .fixedSize(horizontal: false, vertical: true)

            if let audioURL = message.audioURL {
                HStack {
                    Button {
                        CCHaptics.soft()
                        answerAudio.toggle(urlString: audioURL)
                    } label: {
                        Label(
                            answerAudio.isPlaying(urlString: audioURL)
                                ? UIText.pauseSummary : UIText.playSummary,
                            systemImage: answerAudio.isPlaying(urlString: audioURL)
                                ? "pause.fill" : "play.fill"
                        )
                    }
                    .buttonStyle(CCInlineButtonStyle())
                    Spacer()
                }
            } else if !message.text.isEmpty {
                HStack {
                    CardTTSButton(
                        id: "ask:\(message.id.uuidString)",
                        text: message.text,
                        language: appState.selectedLanguage
                    )
                    Spacer()
                }
            }

            if !message.citations.isEmpty {
                CitationRow(citations: message.citations)
            }

            if message.isRefusal {
                Button {
                    appState.path.append(.legalHelp)
                } label: {
                    Label(UIText.legalHelpButton, systemImage: "person.2.fill")
                }
                .buttonStyle(CCSecondaryButtonStyle())
            }
        }
        .padding(CCSpacing.md)
        .background(CCColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: CCRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: CCRadius.card)
                .stroke(message.isRefusal ? CCColor.urgent.opacity(0.4) : Color.black.opacity(0.07),
                        lineWidth: message.isRefusal ? 2 : 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(UIText.askAssistant)\(message.isRefusal ? ", respuesta no dada" : "")")
    }

    private var thinkingBubble: some View {
        HStack {
            HStack(spacing: CCSpacing.sm) {
                ProgressView().controlSize(.small)
                Text(UIText.askThinking)
                    .font(.body)
                    .foregroundStyle(CCColor.inkSecondary)
            }
            .padding(CCSpacing.md)
            .background(CCColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: CCRadius.card))
            Spacer(minLength: CCSpacing.xl)
        }
        .accessibilityLabel(UIText.askThinking)
        .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: Input bar

    private var inputBar: some View {
        VStack(spacing: CCSpacing.sm) {
            if let sendErrorMessage {
                Text(sendErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(CCColor.urgent)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Secondary: text input.
            HStack(spacing: CCSpacing.sm) {
                TextField(UIText.askPlaceholder, text: $inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.plain)
                    .padding(CCSpacing.sm)
                    .background(CCColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: CCRadius.control))
                    .focused($inputFocused)
                    .accessibilityLabel(UIText.askPlaceholder)

                Button {
                    sendText()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(canSendText ? CCColor.primary : CCColor.inkSecondary.opacity(0.4))
                }
                .frame(width: 48, height: 48)
                .disabled(!canSendText)
                .accessibilityLabel(UIText.sendButton)
            }

            // Primary: push-to-talk mic.
            micButton
        }
        .padding(CCSpacing.md)
        .background(CCColor.surface)
    }

    private var micButton: some View {
        VStack(spacing: CCSpacing.xs) {
            ZStack {
                Circle()
                    .fill(recorder.isRecording ? CCColor.urgent : CCColor.primary)
                    .frame(width: CCMetrics.touchTarget + 8, height: CCMetrics.touchTarget + 8)
                Image(systemName: recorder.isRecording ? "waveform" : "mic.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolEffect(.variableColor, isActive: recorder.isRecording)
                    .symbolEffect(.bounce, value: recorder.isRecording)
            }
            .scaleEffect(recorder.isRecording ? 1.12 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.65), value: recorder.isRecording)

            Text(recorder.isRecording ? UIText.micRecording : UIText.micButton)
                .font(.footnote.weight(.medium))
                .foregroundStyle(CCColor.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in beginPushToTalk() }
                .onEnded { _ in endPushToTalk() }
        )
        .disabled(isSending)
        .accessibilityElement()
        .accessibilityLabel(UIText.micA11y)
        .accessibilityHint(UIText.micA11yHint)
        .accessibilityAddTraits(.isButton)
        // VoiceOver users cannot hold a gesture — a double-tap toggles instead.
        .accessibilityAction {
            if recorder.isRecording { endPushToTalk() } else { beginPushToTalk() }
        }
    }

    // MARK: Send actions

    private var canSendText: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    private func sendText() {
        let question = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isSending else { return }
        CCHaptics.light()
        inputText = ""
        inputFocused = false
        messages.append(ChatMessage(role: .user, text: question))
        send(question: question, audioData: nil)
    }

    /// Begin recording on press-down. Handles the permission flow.
    private func beginPushToTalk() {
        guard !recorder.isRecording, !isSending else { return }
        CCHaptics.soft()
        switch recorder.permission {
        case .granted:
            recorder.startRecording()
        case .undetermined:
            Task {
                let granted = await recorder.requestPermission()
                if granted { recorder.startRecording() }
                else { showMicDeniedAlert = true }
            }
        case .denied:
            showMicDeniedAlert = true
        }
    }

    /// Stop recording on release and send the audio.
    private func endPushToTalk() {
        guard recorder.isRecording else { return }
        guard let audioData = recorder.stopRecording() else { return }
        messages.append(ChatMessage(
            role: .user,
            text: UIText.askVoiceQuestion,
            awaitingTranscription: true
        ))
        send(question: nil, audioData: audioData)
    }

    /// POST to /ask and append the answer (or refusal) to the transcript.
    private func send(question: String?, audioData: Data?) {
        sendErrorMessage = nil
        guard let documentId = appState.documentId else {
            sendErrorMessage = UIText.errorGeneric
            return
        }
        isSending = true
        Task {
            defer { isSending = false }
            do {
                let result = try await appState.api.ask(
                    sessionId: appState.sessionId,
                    documentId: documentId,
                    question: question,
                    audioData: audioData
                )
                // Backfill the voice question's transcription, if any.
                if let transcript = result.questionTranscribed,
                   let index = messages.lastIndex(where: { $0.awaitingTranscription }) {
                    messages[index].text = transcript
                    messages[index].awaitingTranscription = false
                }
                if result.wasRefused {
                    // Increment the visible counter — the demo's key moment.
                    CCHaptics.warning()
                    appState.registerRefusal()
                    messages.append(ChatMessage(
                        role: .assistant,
                        text: result.refusalTextEs ?? "",
                        isRefusal: true,
                        citations: result.citations ?? []
                    ))
                } else {
                    messages.append(ChatMessage(
                        role: .assistant,
                        text: result.answerEs ?? "",
                        citations: result.citations ?? [],
                        audioURL: result.answerAudioUrl
                    ))
                }
            } catch let error as APIError {
                sendErrorMessage = AppState.userMessage(for: error)
            } catch {
                sendErrorMessage = UIText.errorGeneric
            }
        }
    }
}
