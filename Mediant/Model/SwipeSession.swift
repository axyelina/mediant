import Observation

/// One run through an album on the swipe screen: the current photo and an undo stack.
/// It goes from the start photo to the last one in order; after the last one it goes on with
/// the photos that have no decision yet (from the top of the album), and finishes only when
/// every photo has one.
@MainActor
@Observable
final class SwipeSession {
    private struct Step {
        let index: Int
        let id: String
        let previous: Decision?
        let decision: Decision
        let wasWrapped: Bool
    }

    let assetIDs: [String]
    private let store: DecisionStore
    private var history: [Step] = []
    /// Past the last photo once: from now on only photos without a decision come up.
    private var isWrapped = false
    private(set) var index: Int

    init(assetIDs: [String], startIndex: Int, store: DecisionStore) {
        self.assetIDs = assetIDs
        self.store = store
        index = min(max(startIndex, 0), assetIDs.count)
    }

    var isFinished: Bool { index >= assetIDs.count }
    var currentID: String? { isFinished ? nil : assetIDs[index] }
    var canUndo: Bool { !history.isEmpty }
    /// The decision that `undo()` would revert.
    var lastCommitted: Decision? { history.last?.decision }

    func commit(_ decision: Decision) {
        guard let id = currentID else { return }
        history.append(Step(index: index, id: id, previous: store.decision(for: id), decision: decision,
                            wasWrapped: isWrapped))
        store.set(decision, for: id)
        let upcoming = upcomingIndex
        isWrapped = isWrapped || index + 1 >= assetIDs.count
        index = upcoming ?? assetIDs.count
    }

    /// Where the next decision leads: the next photo in order up to the last one; after that the
    /// next photo without a decision (after this one, then from the top). Nil: the run finishes.
    var upcomingIndex: Int? {
        guard !isFinished else { return nil }
        let next = index + 1
        if !isWrapped && next < assetIDs.count { return next }
        let order = Array(next..<assetIDs.count) + Array(0..<index)
        return order.first { store.decision(for: assetIDs[$0]) == nil }
    }

    func undo() {
        guard let step = history.popLast() else { return }
        store.set(step.previous, for: step.id)
        index = step.index
        isWrapped = step.wasWrapped
    }

    /// The photo a sideways swipe shows: the neighbor in album order (`step` 1 = next, -1 =
    /// previous), nil past either end or when the run is finished. Browsing decides nothing.
    func neighborIndex(_ step: Int) -> Int? {
        guard !isFinished else { return nil }
        let target = index + step
        return assetIDs.indices.contains(target) ? target : nil
    }

    func jump(to newIndex: Int) {
        guard !assetIDs.isEmpty else { return }
        index = min(max(newIndex, 0), assetIDs.count - 1)
    }
}
