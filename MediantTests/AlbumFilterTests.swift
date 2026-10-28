import Foundation
import Testing
@testable import Mediant

@MainActor
struct AlbumFilterTests {
    let store = DecisionStore(fileURL: FileManager.default.temporaryDirectory
        .appendingPathComponent("filter-\(UUID().uuidString).json"))
    let assets = ["new", "kept", "trashed"].map {
        AssetInfo(id: $0, aspect: 1, isVideo: false, duration: 0)
    }

    init() {
        store.set(.kept, for: "kept")
        store.set(.trashed, for: "trashed")
    }

    @Test func hidesTrashedAndKeptByDefault() {
        #expect(visibleAssets(assets, store: store, showKept: false).map(\.id) == ["new"])
    }

    @Test func showsKeptWhenAsked() {
        #expect(visibleAssets(assets, store: store, showKept: true).map(\.id) == ["new", "kept"])
    }

    @Test func neverShowsTrashed() {
        #expect(!visibleAssets(assets, store: store, showKept: true).map(\.id).contains("trashed"))
    }
}
