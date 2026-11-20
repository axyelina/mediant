import AVFoundation
import Observation

/// The video on the top card: one looping player that the card shows and the chips control
/// (time, sound, scrub). Only one video plays at a time.
///
/// Sound: muted, the app follows the silent switch and leaves the user's music playing (ambient).
/// With the sound turned on (the 🔊 chip, or a volume-up press on a muted video) it plays even
/// when the phone is on silent (playback), like a video app.
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
    private(set) var isMuted: Bool
    private(set) var isScrubbing = false
    /// Paused by the user; a new video always starts playing.
    private(set) var isPaused = false
    /// The Trash tab covers the swipe screen: the video waits, and plays again when it comes back.
    private(set) var isHidden = false

    @ObservationIgnored private var looper: AVPlayerLooper?
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var scrubStart: TimeInterval = 0
    @ObservationIgnored private var volumeObservation: NSKeyValueObservation?
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isMuted = defaults.object(forKey: Self.mutedKey) as? Bool ?? true
        // Volume buttons change the output volume; there is no other public signal for them.
        volumeObservation = AVAudioSession.sharedInstance().observe(\.outputVolume, options: [.old, .new]) {
            [weak self] _, change in
            guard let old = change.oldValue, let new = change.newValue else { return }
            Task { @MainActor in self?.volumeChanged(from: old, to: new) }
        }
    }

    var audioCategory: AVAudioSession.Category { isMuted ? .ambient : .playback }

    func play(_ item: AVPlayerItem, id: String, duration: TimeInterval) {
        stop()
        applyAudioSession()
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
        if !isHidden { player.play() }
    }

    /// Stops the player if it still plays `id` (a card that left may stop after the next one started),
    /// and lets the user's music play again.
    func stop(_ id: String) {
        guard self.id == id else { return }
        stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func toggleMuted() {
        isMuted.toggle()
        defaults.set(isMuted, forKey: Self.mutedKey)
        guard let player else { return }
        applyAudioSession()
        player.isMuted = isMuted
    }

    /// A volume-up press while a video plays muted turns its sound on, the same as the 🔊 chip.
    /// A hidden player ignores it: the press is for the video on screen.
    func volumeChanged(from old: Float, to new: Float) {
        guard new > old, isMuted, player != nil, !isHidden else { return }
        toggleMuted()
    }

    func togglePaused() {
        guard let player else { return }
        isPaused.toggle()
        if isPaused { player.pause() } else if !isScrubbing { player.play() }
    }

    func setHidden(_ hidden: Bool) {
        isHidden = hidden
        // Another player (the Trash viewer) may have changed the saved sound choice meanwhile.
        if !hidden { isMuted = defaults.object(forKey: Self.mutedKey) as? Bool ?? true }
        guard let player else { return }
        if hidden {
            player.pause()
        } else {
            applyAudioSession()
            player.isMuted = isMuted
            if !isPaused && !isScrubbing { player.play() }
        }
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
        if !isPaused && !isHidden { player?.play() }
    }

    /// Active, so the volume buttons report changes while a video is on screen.
    private func applyAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(audioCategory)
        try? session.setActive(true)
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
