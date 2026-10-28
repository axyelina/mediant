import Foundation
import Observation

/// Storage size per album, calculated in the background. Per-asset sizes are cached in memory;
/// album sizes are also saved to `cacheURL`, so the next launch shows them before it measures again.
@MainActor
@Observable
final class AlbumSizes {
    private struct Cache: Codable {
        var sizes: [String: Int64]
        var albumIDs: [String]
        var allPhotosID: String?
    }

    private let library: PhotoLibrary
    private let cacheURL: URL?
    private var sizes: [String: Int64] = [:]
    private var albumIDs: [String] = []
    private var allPhotosID: String?
    /// Albums measured in this launch; the other sizes come from the cache.
    private var measured: Set<String> = []
    @ObservationIgnored private var assetSizes: [String: Int64?] = [:]
    @ObservationIgnored private var running: Task<Void, Never>?

    init(library: PhotoLibrary, cacheURL: URL? = nil) {
        self.library = library
        self.cacheURL = cacheURL
        if let cacheURL, let data = try? Data(contentsOf: cacheURL),
           let cache = try? JSONDecoder().decode(Cache.self, from: data) {
            sizes = cache.sizes
            albumIDs = cache.albumIDs
            allPhotosID = cache.allPhotosID
        }
    }

    func size(of albumID: String) -> Int64? {
        sizes[albumID]
    }

    /// False while the size is a cached value from an earlier launch, or not known yet.
    func isMeasured(_ albumID: String) -> Bool {
        measured.contains(albumID)
    }

    var isTotalMeasured: Bool {
        if let allPhotosID { return measured.contains(allPhotosID) }
        return !albumIDs.isEmpty && albumIDs.allSatisfy(measured.contains)
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
            measured.insert(album.id)
        }
        save()
    }

    private func save() {
        guard let cacheURL else { return }
        let cache = Cache(sizes: sizes.filter { albumIDs.contains($0.key) },
                          albumIDs: albumIDs, allPhotosID: allPhotosID)
        do {
            try FileManager.default.createDirectory(
                at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(cache).write(to: cacheURL, options: .atomic)
        } catch {
            assertionFailure("Saving album sizes failed: \(error)")
        }
    }

    /// Runs off the main actor; cancellation of the calling task reaches PhotoKit enumeration.
    private nonisolated static func sizes(in albumID: String, library: PhotoLibrary,
                                          cached: [String: Int64?]) async -> [String: Int64?] {
        library.fileSizes(inAlbum: albumID, cached: cached)
    }
}
