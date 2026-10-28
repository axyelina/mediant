import Foundation
import Observation

/// Kept/trashed decisions keyed by PhotoKit `localIdentifier`, saved as JSON after every change.
@MainActor
@Observable
final class DecisionStore {
    private struct State: Codable {
        var decisions: [String: Decision] = [:]
        /// Trashed ids in the order they were added (newest last).
        var trash: [String] = []
    }

    private let fileURL: URL
    private var state: State

    init(fileURL: URL) {
        self.fileURL = fileURL
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode(State.self, from: data) {
            state = saved
        } else {
            state = State()
        }
    }

    var trashedIDs: [String] { state.trash }
    var trashCount: Int { state.trash.count }
    /// Every photo with a decision (kept or trashed).
    var knownIDs: [String] { Array(state.decisions.keys) }

    func decision(for id: String) -> Decision? {
        state.decisions[id]
    }

    func set(_ decision: Decision?, for id: String) {
        state.decisions[id] = decision
        state.trash.removeAll { $0 == id }
        if decision == .trashed { state.trash.append(id) }
        save()
    }

    /// Takes photos out of the Trash; they become undecided.
    func restore(_ ids: [String]) {
        forget(Set(ids))
    }

    /// Forgets photos that were deleted from the library.
    func clearTrash(_ ids: [String]) {
        forget(Set(ids))
    }

    /// Drops every id that no longer exists in the photo library.
    func removeMissing(keeping existing: Set<String>) {
        forget(Set(state.decisions.keys).subtracting(existing))
    }

    private func forget(_ ids: Set<String>) {
        guard !ids.isEmpty else { return }
        for id in ids { state.decisions[id] = nil }
        state.trash.removeAll { ids.contains($0) }
        save()
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(state).write(to: fileURL, options: .atomic)
        } catch {
            assertionFailure("Saving decisions failed: \(error)")
        }
    }
}
