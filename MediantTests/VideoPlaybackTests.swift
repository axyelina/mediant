import AVFoundation
import Foundation
import Testing
@testable import Mediant

@MainActor
struct VideoPlaybackTests {
    /// The player never loads it; the pause logic does not need real media.
    func item() -> AVPlayerItem {
        AVPlayerItem(url: FileManager.default.temporaryDirectory.appendingPathComponent("none.mp4"))
    }

    @Test func playsWhenLoaded() {
        let playback = VideoPlayback()
        playback.play(item(), id: "a", duration: 10)
        #expect(!playback.isPaused)
    }

    @Test func toggleSwitchesBetweenPausedAndPlaying() {
        let playback = VideoPlayback()
        playback.play(item(), id: "a", duration: 10)
        playback.togglePaused()
        #expect(playback.isPaused)
        playback.togglePaused()
        #expect(!playback.isPaused)
    }

    @Test func toggleWithoutVideoDoesNothing() {
        let playback = VideoPlayback()
        playback.togglePaused()
        #expect(!playback.isPaused)
    }

    @Test func scrubKeepsAPausedVideoPaused() {
        let playback = VideoPlayback()
        playback.play(item(), id: "a", duration: 10)
        playback.togglePaused()
        playback.beginScrub()
        playback.scrub(by: 30, width: 300)
        playback.endScrub()
        #expect(playback.isPaused)
        #expect(playback.time == 1)
    }

    @Test func nextVideoStartsPlaying() {
        let playback = VideoPlayback()
        playback.play(item(), id: "a", duration: 10)
        playback.togglePaused()
        playback.play(item(), id: "b", duration: 10)
        #expect(!playback.isPaused)
    }
}
