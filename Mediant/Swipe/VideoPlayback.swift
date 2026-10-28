import AVFoundation
import Observation

/// The video on the top card: one looping player that the card shows and the chips control
/// (time, sound, scrub). Only one video plays at a time.
@MainActor
@Observable
final class VideoPlayback {
    private static let mutedKey = "videoMuted"

    private(set) var player: AVQueuePlayer?
    /// The asset that `player` plays.
    private(set) var id: String?
    private(set) var time: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    /// Remembered between launches; muted until the user turns the sound on.
    private(set) var isMuted = UserDefaults.standard.object(forKey: mutedKey) as? Bool ?? true
    private(set) var isScrubbing = false
    /// Paused by the user; a new video always starts playing.
    private(set) var isPaused = false

    @ObservationIgnored private var looper: AVPlayerLooper?
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var scrubStart: TimeInterval = 0

    func play(_ item: AVPlayerItem, id: String, duration: TimeInterval) {
        stop()
        // Ambient: follows the silent switch and does not stop the user's music.
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        let player = AVQueuePlayer()
        player.isMuted = isMuted
        looper = AVPlayerLooper(player: player, templateItem: item)
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 10), queue: .main) {
            [weak self] now in
            MainActor.assumeIsolated {
                guard let self, !self.isScrubbing else { return }
                self.time = now.seconds
            }
        }
        self.player = player
        self.id = id
        self.duration = duration
        time = 0
        isPaused = false
        player.play()
    }

    /// Stops the player if it still plays `id` (a card that left may stop after the next one started).
    func stop(_ id: String) {
        if self.id == id { stop() }
    }

    func toggleMuted() {
        isMuted.toggle()
        player?.isMuted = isMuted
        UserDefaults.standard.set(isMuted, forKey: Self.mutedKey)
    }

    func togglePaused() {
        guard let player else { return }
        isPaused.toggle()
        if isPaused { player.pause() } else if !isScrubbing { player.play() }
    }

    func beginScrub() {
        guard player != nil, !isScrubbing else { return }
        isScrubbing = true
        scrubStart = time
        player?.pause()
    }

    /// `translation` across `width` points covers the whole video.
    func scrub(by translation: Double, width: Double) {
        guard isScrubbing else { return }
        time = VideoTime.scrubbed(from: scrubStart, by: translation, width: width, duration: duration)
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func endScrub() {
        guard isScrubbing else { return }
        isScrubbing = false
        if !isPaused { player?.play() }
    }

    private func stop() {
        player?.pause()
        if let timeObserver { player?.removeTimeObserver(timeObserver) }
        timeObserver = nil
        looper = nil
        player = nil
        id = nil
        isScrubbing = false
        isPaused = false
        time = 0
    }
}
