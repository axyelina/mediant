import Foundation
import Observation

/// Storage size per album, calculated in the background. Per-asset sizes are cached in memory.
@MainActor
@Observable
final class AlbumSizes {
    private let library: PhotoLibrary
    private var sizes: [String: Int64] = [:]
    private var albumIDs: [String] = []
    private var allPhotosID: String?
    @ObservationIgnored private var assetSizes: [String: Int64?] = [:]
    @ObservationIgnored private var running: Task<Void, Never>?

    init(library: PhotoLibrary) {
        self.library = library
    }

    func size(of albumID: String) -> Int64? {
        sizes[albumID]
    }

    /// The all-photos album size when there is one, else the sum of all albums.
    var total: Int64? {
        if let allPhotosID { return sizes[allPhotosID] }
        let known = albumIDs.compactMap { sizes[$0] }
        return known.isEmpty ? nil : known.reduce(0, +)
    }

    /// Recalculates all albums. A newer call cancels a running one.
    func refresh(_ albums: [AlbumInfo]) async {
        running?.cancel()
        let task = Task { await measure(albums) }
        running = task
        await task.value
    }

    private func measure(_ albums: [AlbumInfo]) async {
        albumIDs = albums.map(\.id)
        allPhotosID = albums.first(where: \.isAllPhotos)?.id
        // All-photos first: it fills the cache for every other album.
        for album in albums.sorted(by: { $0.isAllPhotos && !$1.isAllPhotos }) {
            let found = await Self.sizes(in: album.id, library: library, cached: assetSizes)
            guard !Task.isCancelled else { return }
            assetSizes.merge(found) { _, new in new }
            let known = found.values.compactMap { $0 }
            sizes[album.id] = known.isEmpty ? nil : known.reduce(0, +)
        }
    }

    /// Runs off the main actor; cancellation of the calling task reaches PhotoKit enumeration.
    private nonisolated static func sizes(in albumID: String, library: PhotoLibrary,
                                          cached: [String: Int64?]) async -> [String: Int64?] {
        library.fileSizes(inAlbum: albumID, cached: cached)
    }
}
