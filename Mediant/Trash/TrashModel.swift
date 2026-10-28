import Foundation
import Observation

/// Trash tab state: selection for restoring, and the one-batch delete.
@MainActor
@Observable
final class TrashModel {
    private let store: DecisionStore
    private let library: PhotoLibrary

    var isSelecting = false
    var selection: Set<String> = []
    private(set) var totalBytes: Int64?
    private(set) var isDeleting = false
    /// Increments after each successful delete (drives the success haptic).
    private(set) var deleteCount = 0

    init(store: DecisionStore, library: PhotoLibrary) {
        self.store = store
        self.library = library
    }

    func toggle(_ id: String) {
        if selection.contains(id) { selection.remove(id) } else { selection.insert(id) }
    }

    func cancelSelecting() {
        selection = []
        isSelecting = false
    }

    func restoreSelected() {
        store.restore(Array(selection))
        cancelSelecting()
    }

    /// Deletes everything in the Trash with one iOS dialog. If the user declines, nothing changes.
    func emptyTrash() async {
        let ids = store.trashedIDs
        guard !ids.isEmpty, !isDeleting else { return }
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await library.delete(ids)
            store.clearTrash(ids)
            totalBytes = nil
            deleteCount += 1
        } catch {
            // Declined in the iOS dialog: keep the Trash as it is.
        }
    }

    func refreshSize() async {
        let ids = store.trashedIDs
        let library = library
        totalBytes = await Task.detached(priority: .utility) {
            let sizes = ids.compactMap { library.fileSize(ofAsset: $0) }
            return sizes.isEmpty ? nil : sizes.reduce(0, +)
        }.value
    }
}
