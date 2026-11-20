import AVFoundation
import Foundation
import Testing
@testable import Mediant

@MainActor
struct VideoPlaybackTests {
    /// Its own settings, so tests do not change the app's saved sound choice.
    let defaults = UserDefaults(suiteName: "playback-\(UUID().uuidString)")!

    /// The player never loads it; the logic here does not need real media.
    func item() -> AVPlayerItem {
        AVPlayerItem(url: FileManager.default.temporaryDirectory.appendingPathComponent("none.mp4"))
    }

    func makePlayback() -> VideoPlayback { VideoPlayback(defaults: defaults) }

    @Test func playsWhenLoaded() {
        let playback = makePlayback()
        playback.play(item(), id: "a", duration: 10)
        #expect(!playback.isPaused)
    }

    @Test func toggleSwitchesBetweenPausedAndPlaying() {
        let playback = makePlayback()
        playback.play(item(), id: "a", duration: 10)
        playback.togglePaused()
        #expect(playback.isPaused)
        playback.togglePaused()
        #expect(!playback.isPaused)
    }

    @Test func toggleWithoutVideoDoesNothing() {
        let playback = makePlayback()
        playback.togglePaused()
        #expect(!playback.isPaused)
    }

    @Test func scrubKeepsAPausedVideoPaused() {
        let playback = makePlayback()
        playback.play(item(), id: "a", duration: 10)
        playback.togglePaused()
        playback.beginScrub()
        playback.scrub(by: 30, width: 300)
        playback.endScrub()
        #expect(playback.isPaused)
        #expect(playback.time == 1)
    }

    @Test func nextVideoStartsPlaying() {
        let playback = makePlayback()
        playback.play(item(), id: "a", duration: 10)
        playback.togglePaused()
        playback.play(item(), id: "b", duration: 10)
        #expect(!playback.isPaused)
    }

    @Test func mutedByDefault() {
        #expect(makePlayback().isMuted)
    }

    @Test func soundChoiceIsRemembered() {
        makePlayback().toggleMuted()
        #expect(!makePlayback().isMuted)
    }

    @Test func soundOnIgnoresTheSilentSwitch() {
        let playback = makePlayback()
        // Muted: ambient follows the silent switch and leaves the user's music playing.
        #expect(playback.audioCategory == .ambient)
        playback.toggleMuted()
        // Sound on: playback category plays even when the phone is on silent.
        #expect(playback.audioCategory == .playback)
    }

    @Test func volumeUpTurnsTheSoundOn() {
        let playback = makePlayback()
        playback.play(item(), id: "a", duration: 10)
        playback.volumeChanged(from: 0.4, to: 0.5)
        #expect(!playback.isMuted)
        #expect(!makePlayback().isMuted)
    }

    @Test func volumeDownKeepsItMuted() {
        let playback = makePlayback()
        playback.play(item(), id: "a", duration: 10)
        playback.volumeChanged(from: 0.5, to: 0.4)
        #expect(playback.isMuted)
    }

    @Test func volumeUpWithoutVideoKeepsItMuted() {
        let playback = makePlayback()
        playback.volumeChanged(from: 0.4, to: 0.5)
        #expect(playback.isMuted)
    }

    @Test func hiddenVideoStopsAndComesBackPlaying() {
        let playback = makePlayback()
        playback.play(item(), id: "a", duration: 10)
        playback.setHidden(true)
        #expect(playback.player?.rate == 0)
        #expect(!playback.isPaused)
        playback.setHidden(false)
        #expect(playback.player?.rate != 0)
    }

    @Test func hiddenVideoPausedByTheUserStaysPaused() {
        let playback = makePlayback()
        playback.play(item(), id: "a", duration: 10)
        playback.togglePaused()
        playback.setHidden(true)
        playback.setHidden(false)
        #expect(playback.isPaused)
        #expect(playback.player?.rate == 0)
    }

    @Test func nextVideoWhileHiddenWaits() {
        let playback = makePlayback()
        playback.setHidden(true)
        playback.play(item(), id: "a", duration: 10)
        #expect(playback.player?.rate == 0)
    }

    /// The Trash viewer has its own player; a swipe screen behind it picks up the sound choice
    /// made there when it shows again.
    @Test func comingBackPicksUpTheSoundChoiceMadeElsewhere() {
        let swipe = makePlayback()
        swipe.play(item(), id: "a", duration: 10)
        swipe.setHidden(true)
        makePlayback().toggleMuted()
        swipe.setHidden(false)
        #expect(!swipe.isMuted)
        #expect(swipe.player?.isMuted == false)
    }

    @Test func volumeUpWhileHiddenChangesNothing() {
        let playback = makePlayback()
        playback.play(item(), id: "a", duration: 10)
        playback.setHidden(true)
        playback.volumeChanged(from: 0.4, to: 0.5)
        #expect(playback.isMuted)
    }
}
