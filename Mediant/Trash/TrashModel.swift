import Foundation
import Observation

/// Trash tab state: selection for restoring, and the one-batch delete.
@MainActor
@Observable
final class TrashModel {
    private let store: DecisionStore
    private let library: PhotoLibrary
    private let stats: CleanupStats

    var isSelecting = false
    var selection: Set<String> = []
    private(set) var totalBytes: Int64?
    private(set) var isDeleting = false
    /// Set when deleting failed for a reason other than the user declining.
    var errorMessage: String?
    /// Increments after each successful delete (drives the success haptic).
    private(set) var deleteCount = 0

    init(store: DecisionStore, library: PhotoLibrary, stats: CleanupStats) {
        self.store = store
        self.library = library
        self.stats = stats
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
        errorMessage = nil
        defer { isDeleting = false }
        // Measure before deleting: afterwards the photos are gone.
        let sizes = await Self.sizes(of: ids, library: library)
        do {
            let deleted = try await library.delete(ids)
            stats.record(deleted: deleted.count, bytes: deleted.compactMap { sizes[$0] }.reduce(Int64(0), +))
            store.clearTrash(ids)
            totalBytes = nil
            deleteCount += 1
        } catch DeleteError.declined {
            // "Don't Allow" in the iOS dialog: keep the Trash as it is.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private nonisolated static func sizes(of ids: [String], library: PhotoLibrary) async -> [String: Int64] {
        var sizes: [String: Int64] = [:]
        for id in ids { sizes[id] = library.fileSize(ofAsset: id) }
        return sizes
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
