//
//  AudioPlayback.swift
//  Carta Clara
//
//  Plays Polly-synthesized Spanish audio from a presigned S3 URL.
//
//  Audio playback reading the Spanish summary aloud is a core accessibility
//  feature — the grandma test (TENETS.md §5) assumes she may not read fluently.
//

import AVFoundation
import Combine
import Foundation

/// Observable wrapper around AVPlayer for streaming remote MP3 audio.
///
/// One instance per audio source (the summary card and the chat answer each
/// own their own), so `isPlaying` reflects exactly one clip.
@MainActor
final class AudioPlayback: ObservableObject {

    /// True while audio is actively playing. Drives the play/pause button.
    @Published private(set) var isPlaying = false
    /// True while the clip is buffering after a tap.
    @Published private(set) var isLoading = false
    /// Set when playback fails; views surface a quiet, non-blocking message.
    @Published private(set) var failed = false
    /// The URL of the clip currently loaded — lets a view with several play
    /// buttons (e.g. the chat) know which one is active.
    @Published private(set) var currentURLString: String?

    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?
    private var statusObservation: NSKeyValueObservation?

    deinit {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
    }

    /// Toggle playback for the clip at `urlString`. A nil/blank URL is a no-op.
    ///
    /// Tapping the *same* clip pauses/resumes it; tapping a *different* clip
    /// switches to it from the start.
    func toggle(urlString: String?) {
        guard let urlString, let url = URL(string: urlString) else { return }
        if urlString != currentURLString {
            // A different clip — tear down and load the new one.
            stop()
            currentURLString = urlString
            play(url: url)
        } else if isPlaying {
            pause()
        } else {
            play(url: url)
        }
    }

    /// Returns true if `urlString` is the clip currently playing.
    func isPlaying(urlString: String?) -> Bool {
        isPlaying && urlString != nil && urlString == currentURLString
    }

    /// Stop and release the player. Call when the owning view disappears.
    func stop() {
        player?.pause()
        player = nil
        isPlaying = false
        isLoading = false
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        statusObservation = nil
    }

    private func play(url: URL) {
        failed = false
        configureSessionForPlayback()

        // Reuse the player if it already holds this clip (resume), else build.
        if player == nil {
            let item = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: item)
            self.player = player

            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.handleDidFinish() }
            }

            isLoading = true
            statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
                Task { @MainActor in
                    guard let self else { return }
                    switch item.status {
                    case .readyToPlay:
                        self.isLoading = false
                    case .failed:
                        self.isLoading = false
                        self.failed = true
                        self.isPlaying = false
                    default:
                        break
                    }
                }
            }
        }
        player?.play()
        isPlaying = true
    }

    private func pause() {
        player?.pause()
        isPlaying = false
    }

    private func handleDidFinish() {
        isPlaying = false
        // Rewind so the next tap replays from the start.
        player?.seek(to: .zero)
    }

    /// Use `.playback` so audio is audible even with the ringer switch silenced —
    /// grandma may not know about the silent switch.
    private func configureSessionForPlayback() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
    }
}
