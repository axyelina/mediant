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

    func refresh(_ albums: [AlbumInfo]) async {
        albumIDs = albums.map(\.id)
        allPhotosID = albums.first(where: \.isAllPhotos)?.id
        // All-photos first: it fills the cache for every other album.
        for album in albums.sorted(by: { $0.isAllPhotos && !$1.isAllPhotos }) {
            let library = library
            let cache = assetSizes
            let (sum, found) = await Task.detached(priority: .utility) {
                var found: [String: Int64?] = [:]
                var sum: Int64?
                for asset in library.assets(inAlbum: album.id) {
                    let size = cache[asset.id] ?? library.fileSize(ofAsset: asset.id)
                    found[asset.id] = size
                    if let size { sum = (sum ?? 0) + size }
                }
                return (sum, found)
            }.value
            assetSizes.merge(found) { _, new in new }
            sizes[album.id] = sum
        }
    }
}
