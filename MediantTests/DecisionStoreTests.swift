import Foundation
import Testing
@testable import Mediant

@MainActor
struct DecisionStoreTests {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("decisions-\(UUID().uuidString).json")

    @Test func setAndReadBack() {
        let store = DecisionStore(fileURL: url)
        store.set(.trashed, for: "a")
        store.set(.kept, for: "b")
        #expect(store.decision(for: "a") == .trashed)
        #expect(store.decision(for: "b") == .kept)
        #expect(store.decision(for: "c") == nil)
        #expect(store.trashedIDs == ["a"])
        #expect(store.trashCount == 1)
    }

    @Test func persistsAcrossInstances() {
        let first = DecisionStore(fileURL: url)
        first.set(.trashed, for: "a")
        first.set(.kept, for: "b")
        let second = DecisionStore(fileURL: url)
        #expect(second.trashedIDs == ["a"])
        #expect(second.decision(for: "b") == .kept)
    }

    @Test func retrashKeepsSingleEntry() {
        let store = DecisionStore(fileURL: url)
        store.set(.trashed, for: "a")
        store.set(.kept, for: "a")
        store.set(.trashed, for: "a")
        #expect(store.trashedIDs == ["a"])
    }

    @Test func restoreMakesUndecided() {
        let store = DecisionStore(fileURL: url)
        store.set(.trashed, for: "a")
        store.set(.trashed, for: "b")
        store.restore(["a"])
        #expect(store.decision(for: "a") == nil)
        #expect(store.trashedIDs == ["b"])
    }

    @Test func removeMissingDropsUnknownIDs() {
        let store = DecisionStore(fileURL: url)
        store.set(.trashed, for: "a")
        store.set(.trashed, for: "b")
        store.set(.kept, for: "c")
        store.removeMissing(keeping: ["a"])
        #expect(store.trashedIDs == ["a"])
        #expect(store.decision(for: "c") == nil)
    }

    @Test func clearTrashForgetsIDs() {
        let store = DecisionStore(fileURL: url)
        store.set(.trashed, for: "a")
        store.set(.trashed, for: "b")
        store.clearTrash(["a"])
        #expect(store.trashedIDs == ["b"])
        #expect(store.decision(for: "a") == nil)
    }

    @Test func knownIDsListsEveryDecidedPhoto() {
        let store = DecisionStore(fileURL: url)
        store.set(.trashed, for: "a")
        store.set(.kept, for: "b")
        #expect(Set(store.knownIDs) == ["a", "b"])
    }

    @Test func corruptFileStartsEmpty() throws {
        try Data("not json".utf8).write(to: url)
        let store = DecisionStore(fileURL: url)
        #expect(store.trashedIDs.isEmpty)
    }
}
