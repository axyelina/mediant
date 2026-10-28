import Foundation
import Testing
@testable import Mediant

@MainActor
struct CleanupStatsTests {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("stats-\(UUID().uuidString).json")

    @Test func startsAtZero() {
        let stats = CleanupStats(fileURL: url)
        #expect(stats.deletedCount == 0)
        #expect(stats.freedBytes == 0)
    }

    @Test func recordAddsUp() {
        let stats = CleanupStats(fileURL: url)
        stats.record(deleted: 2, bytes: 300)
        stats.record(deleted: 1, bytes: 50)
        #expect(stats.deletedCount == 3)
        #expect(stats.freedBytes == 350)
    }

    @Test func persistsAcrossInstances() {
        CleanupStats(fileURL: url).record(deleted: 4, bytes: 1_000)
        let again = CleanupStats(fileURL: url)
        #expect(again.deletedCount == 4)
        #expect(again.freedBytes == 1_000)
    }
}

@MainActor
struct StripLayoutTests {
    func asset(_ id: String, _ aspect: Double) -> AssetInfo {
        AssetInfo(id: id, aspect: aspect, isVideo: false, duration: 0)
    }

    @Test func currentIsCenteredAndNeighboursDoNotOverlap() {
        let assets = [asset("a", 1), asset("b", 1), asset("c", 1)]
        let centers = PreviewStrip.centers(around: 1, in: assets)
        #expect(centers[1] == 0)
        // current 42 wide, others 36 wide, gap 4: 21 + 4 + 18 = 43
        #expect(centers[2] == 43)
        #expect(centers[0] == -43)
    }

    @Test func dragPicksTheTileNearestTheCenter() {
        let assets = [asset("a", 1), asset("b", 1), asset("c", 1)]
        #expect(PreviewStrip.index(scrolledBy: 0, around: 1, in: assets) == 1)
        #expect(PreviewStrip.index(scrolledBy: 15, around: 1, in: assets) == 1)
        // Dragging left by 40 brings tile 2 (center 43) to 3 pt from the middle.
        #expect(PreviewStrip.index(scrolledBy: -40, around: 1, in: assets) == 2)
        #expect(PreviewStrip.index(scrolledBy: 50, around: 1, in: assets) == 0)
    }

    @Test func dragPastTheEndStopsAtTheLastTile() {
        let assets = [asset("a", 1), asset("b", 1), asset("c", 1)]
        #expect(PreviewStrip.index(scrolledBy: -1_000, around: 1, in: assets) == 2)
        #expect(PreviewStrip.index(scrolledBy: 1_000, around: 1, in: assets) == 0)
    }

    @Test func dragIsLimitedBetweenTheFirstAndLastTile() {
        let assets = [asset("a", 1), asset("b", 1), asset("c", 1)]
        #expect(PreviewStrip.scrollRange(around: 1, in: assets) == -43...43)
        #expect(PreviewStrip.scrollRange(around: 0, in: assets) == -(43 + 40)...0)
    }
}
