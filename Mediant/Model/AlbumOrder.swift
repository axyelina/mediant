import Foundation

/// Smart albums that always lead the albums list, in this order.
enum PinnedAlbum: Int, CaseIterable, Hashable {
    case favorites, recentlyAdded, videos, screenshots, selfies
}

/// The albums list order: the pinned albums first (Favorites, Recently Added, Videos, Screenshots,
/// Selfies), then Recents (all photos), then the other albums by title.
func orderedAlbums(_ albums: [AlbumInfo]) -> [AlbumInfo] {
    albums.sorted { lhs, rhs in
        switch (lhs.pinned, rhs.pinned) {
        case let (l?, r?): return l.rawValue < r.rawValue
        case (_?, nil): return true
        case (nil, _?): return false
        case (nil, nil): break
        }
        if lhs.isAllPhotos != rhs.isAllPhotos { return lhs.isAllPhotos }
        return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
    }
}
