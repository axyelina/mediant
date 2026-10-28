import Observation

/// One run through an album on the swipe screen: the current photo and an undo stack.
@MainActor
@Observable
final class SwipeSession {
    private struct Step {
        let index: Int
        let id: String
        let previous: Decision?
    }

    let assetIDs: [String]
    private let store: DecisionStore
    private var history: [Step] = []
    private(set) var index: Int

    init(assetIDs: [String], startIndex: Int, store: DecisionStore) {
        self.assetIDs = assetIDs
        self.store = store
        index = min(max(startIndex, 0), assetIDs.count)
    }

    var isFinished: Bool { index >= assetIDs.count }
    var currentID: String? { isFinished ? nil : assetIDs[index] }
    var canUndo: Bool { !history.isEmpty }

    func commit(_ decision: Decision) {
        guard let id = currentID else { return }
        history.append(Step(index: index, id: id, previous: store.decision(for: id)))
        store.set(decision, for: id)
        index += 1
    }

    func undo() {
        guard let step = history.popLast() else { return }
        store.set(step.previous, for: step.id)
        index = step.index
    }

    func jump(to newIndex: Int) {
        guard !assetIDs.isEmpty else { return }
        index = min(max(newIndex, 0), assetIDs.count - 1)
    }
}
