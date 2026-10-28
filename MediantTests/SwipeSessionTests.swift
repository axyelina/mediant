import Foundation
import Testing
@testable import Mediant

@MainActor
struct SwipeSessionTests {
    let store = DecisionStore(fileURL: FileManager.default.temporaryDirectory
        .appendingPathComponent("session-\(UUID().uuidString).json"))

    @Test func startsAtGivenIndex() {
        let session = SwipeSession(assetIDs: ["a", "b", "c"], startIndex: 1, store: store)
        #expect(session.index == 1)
        #expect(session.currentID == "b")
        #expect(!session.canUndo)
    }

    @Test func commitAdvancesAndRecords() {
        let session = SwipeSession(assetIDs: ["a", "b"], startIndex: 0, store: store)
        session.commit(.trashed)
        #expect(session.index == 1)
        #expect(store.decision(for: "a") == .trashed)
        #expect(session.canUndo)
    }

    @Test func undoRestoresPreviousDecision() {
        store.set(.kept, for: "a")
        let session = SwipeSession(assetIDs: ["a", "b"], startIndex: 0, store: store)
        session.commit(.trashed)
        session.undo()
        #expect(session.index == 0)
        #expect(store.decision(for: "a") == .kept)
        #expect(store.trashedIDs.isEmpty)
    }

    @Test func undoWithEmptyHistoryIsNoop() {
        let session = SwipeSession(assetIDs: ["a", "b"], startIndex: 1, store: store)
        session.undo()
        #expect(session.index == 1)
    }

    @Test func finishesAfterLast() {
        let session = SwipeSession(assetIDs: ["a", "b"], startIndex: 0, store: store)
        session.commit(.kept)
        session.commit(.trashed)
        #expect(session.isFinished)
        #expect(session.currentID == nil)
    }

    @Test func undoAfterFinishReturnsToLast() {
        let session = SwipeSession(assetIDs: ["a", "b"], startIndex: 0, store: store)
        session.commit(.kept)
        session.commit(.trashed)
        session.undo()
        #expect(!session.isFinished)
        #expect(session.currentID == "b")
        #expect(store.decision(for: "b") == nil)
    }

    @Test func lastCommittedTellsUndoDirection() {
        let session = SwipeSession(assetIDs: ["a", "b"], startIndex: 0, store: store)
        #expect(session.lastCommitted == nil)
        session.commit(.trashed)
        #expect(session.lastCommitted == .trashed)
        session.commit(.kept)
        #expect(session.lastCommitted == .kept)
        session.undo()
        #expect(session.lastCommitted == .trashed)
    }

    @Test func skipAdvancesWithoutDeciding() {
        store.set(.kept, for: "a")
        let session = SwipeSession(assetIDs: ["a", "b"], startIndex: 0, store: store)
        session.skip()
        #expect(session.currentID == "b")
        #expect(store.decision(for: "a") == .kept)
        #expect(!session.canUndo)
    }

    @Test func skipPastLastFinishes() {
        let session = SwipeSession(assetIDs: ["a", "b"], startIndex: 1, store: store)
        session.skip()
        #expect(session.isFinished)
        session.skip()
        #expect(session.index == 2)
    }

    @Test func jumpClamps() {
        let session = SwipeSession(assetIDs: ["a", "b", "c"], startIndex: 0, store: store)
        session.jump(to: 2)
        #expect(session.currentID == "c")
        session.jump(to: 99)
        #expect(session.index == 2)
        session.jump(to: -5)
        #expect(session.index == 0)
    }
}
