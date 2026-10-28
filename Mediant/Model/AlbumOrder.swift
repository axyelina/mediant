import Foundation

/// Smart albums that lead the albums list right after Recents, in this order.
enum PinnedAlbum: Int, CaseIterable, Hashable {
    case favorites, recentlyAdded, videos, screenshots, selfies
}

/// The albums list order: Recents (all photos) first, then the pinned albums (Favorites, Recently
/// Added, Videos, Screenshots, Selfies), then the other albums by title.
func orderedAlbums(_ albums: [AlbumInfo]) -> [AlbumInfo] {
    albums.sorted { lhs, rhs in
        if lhs.isAllPhotos != rhs.isAllPhotos { return lhs.isAllPhotos }
        switch (lhs.pinned, rhs.pinned) {
        case let (l?, r?): return l.rawValue < r.rawValue
        case (_?, nil): return true
        case (nil, _?): return false
        case (nil, nil): return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
    }
}
