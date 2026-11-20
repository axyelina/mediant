import Foundation
import Testing
@testable import Mediant

@MainActor
struct TrashModelTests {
    struct Broken: Error {}

    let library = FakePhotoLibrary()
    let store = DecisionStore(fileURL: FileManager.default.temporaryDirectory
        .appendingPathComponent("trash-\(UUID().uuidString).json"))
    let stats = CleanupStats(fileURL: FileManager.default.temporaryDirectory
        .appendingPathComponent("stats-\(UUID().uuidString).json"))

    @Test func emptyTrashClearsOnSuccess() async {
        store.set(.trashed, for: "a")
        store.set(.trashed, for: "b")
        let trash = TrashModel(store: store, library: library, stats: stats)
        await trash.emptyTrash()
        #expect(library.deleted == ["a", "b"])
        #expect(store.trashedIDs.isEmpty)
        #expect(trash.errorMessage == nil)
    }

    @Test func declinedDeleteKeepsIDsSilently() async {
        store.set(.trashed, for: "a")
        library.deleteError = DeleteError.declined
        let trash = TrashModel(store: store, library: library, stats: stats)
        await trash.emptyTrash()
        #expect(store.trashedIDs == ["a"])
        #expect(trash.errorMessage == nil)
    }

    @Test func failedDeleteKeepsIDsAndShowsError() async {
        store.set(.trashed, for: "a")
        library.deleteError = Broken()
        let trash = TrashModel(store: store, library: library, stats: stats)
        await trash.emptyTrash()
        #expect(store.trashedIDs == ["a"])
        #expect(trash.errorMessage != nil)
    }

    @Test func emptyTrashRecordsProgress() async {
        library.sizes = ["a": 100, "b": 250]
        store.set(.trashed, for: "a")
        store.set(.trashed, for: "b")
        let trash = TrashModel(store: store, library: library, stats: stats)
        await trash.emptyTrash()
        #expect(stats.deletedCount == 2)
        #expect(stats.freedBytes == 350)
    }

    @Test func progressCountsOnlyPhotosReallyDeleted() async {
        library.sizes = ["a": 100, "b": 250]
        library.undeletable = ["b"]
        store.set(.trashed, for: "a")
        store.set(.trashed, for: "b")
        let trash = TrashModel(store: store, library: library, stats: stats)
        await trash.emptyTrash()
        #expect(stats.deletedCount == 1)
        #expect(stats.freedBytes == 100)
    }

    @Test func declinedDeleteRecordsNothing() async {
        store.set(.trashed, for: "a")
        library.deleteError = DeleteError.declined
        let trash = TrashModel(store: store, library: library, stats: stats)
        await trash.emptyTrash()
        #expect(stats.deletedCount == 0)
    }

    @Test func restoreSelectedUntrashesAndExitsSelect() {
        store.set(.trashed, for: "a")
        store.set(.trashed, for: "b")
        let trash = TrashModel(store: store, library: library, stats: stats)
        trash.isSelecting = true
        trash.selection = ["a"]
        trash.restoreSelected()
        #expect(store.trashedIDs == ["b"])
        #expect(store.decision(for: "a") == nil)
        #expect(!trash.isSelecting)
        #expect(trash.selection.isEmpty)
    }

    @Test func totalBytesSumsKnownSizes() async {
        library.sizes = ["a": 100, "b": 250]
        store.set(.trashed, for: "a")
        store.set(.trashed, for: "b")
        let trash = TrashModel(store: store, library: library, stats: stats)
        await trash.refreshSize()
        #expect(trash.totalBytes == 350)
    }

    @Test func successfulDeleteRemembersWhatWasFreed() async {
        library.sizes = ["a": 100, "b": 50]
        store.set(.trashed, for: "a")
        store.set(.trashed, for: "b")
        let trash = TrashModel(store: store, library: library, stats: stats)
        await trash.emptyTrash()
        #expect(trash.justEmptied == EmptiedTrash(count: 2, bytes: 150))
    }

    @Test func deleteWithoutSizesHasNoBytes() async {
        store.set(.trashed, for: "a")
        store.set(.trashed, for: "b")
        let trash = TrashModel(store: store, library: library, stats: stats)
        await trash.emptyTrash()
        #expect(trash.justEmptied == EmptiedTrash(count: 2, bytes: nil))
    }

    @Test func declinedOrFailedDeleteIsNotJustEmptied() async {
        store.set(.trashed, for: "a")
        let trash = TrashModel(store: store, library: library, stats: stats)
        library.deleteError = DeleteError.declined
        await trash.emptyTrash()
        #expect(trash.justEmptied == nil)
        library.deleteError = Broken()
        await trash.emptyTrash()
        #expect(trash.justEmptied == nil)
    }

    @Test func endJustEmptiedClears() async {
        store.set(.trashed, for: "a")
        let trash = TrashModel(store: store, library: library, stats: stats)
        await trash.emptyTrash()
        #expect(trash.justEmptied != nil)
        trash.endJustEmptied()
        #expect(trash.justEmptied == nil)
    }

    @Test func restoreOneTakesOnlyThatItem() {
        store.set(.trashed, for: "a")
        store.set(.trashed, for: "b")
        let trash = TrashModel(store: store, library: library, stats: stats)
        trash.restore("a")
        #expect(store.trashedIDs == ["b"])
        #expect(store.decision(for: "a") == nil)
    }
}
