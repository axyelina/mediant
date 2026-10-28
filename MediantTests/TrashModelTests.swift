import Foundation
import Testing
@testable import Mediant

@MainActor
struct TrashModelTests {
    struct Broken: Error {}

    let library = FakePhotoLibrary()
    let store = DecisionStore(fileURL: FileManager.default.temporaryDirectory
        .appendingPathComponent("trash-\(UUID().uuidString).json"))

    @Test func emptyTrashClearsOnSuccess() async {
        store.set(.trashed, for: "a")
        store.set(.trashed, for: "b")
        let trash = TrashModel(store: store, library: library)
        await trash.emptyTrash()
        #expect(library.deleted == ["a", "b"])
        #expect(store.trashedIDs.isEmpty)
        #expect(trash.errorMessage == nil)
    }

    @Test func declinedDeleteKeepsIDsSilently() async {
        store.set(.trashed, for: "a")
        library.deleteError = DeleteError.declined
        let trash = TrashModel(store: store, library: library)
        await trash.emptyTrash()
        #expect(store.trashedIDs == ["a"])
        #expect(trash.errorMessage == nil)
    }

    @Test func failedDeleteKeepsIDsAndShowsError() async {
        store.set(.trashed, for: "a")
        library.deleteError = Broken()
        let trash = TrashModel(store: store, library: library)
        await trash.emptyTrash()
        #expect(store.trashedIDs == ["a"])
        #expect(trash.errorMessage != nil)
    }

    @Test func restoreSelectedUntrashesAndExitsSelect() {
        store.set(.trashed, for: "a")
        store.set(.trashed, for: "b")
        let trash = TrashModel(store: store, library: library)
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
        let trash = TrashModel(store: store, library: library)
        await trash.refreshSize()
        #expect(trash.totalBytes == 350)
    }
}
