import Foundation

enum AccessLevel {
    case notDetermined, full, limited, denied
}

struct AlbumInfo: Identifiable, Hashable {
    let id: String
    let title: String
    let count: Int
    let coverAssetID: String?
    /// The "Recents" / all-photos album; its size is the library total.
    var isAllPhotos = false
    /// Set for the smart albums that lead the list (see `orderedAlbums`).
    var pinned: PinnedAlbum?
}

struct AssetInfo: Identifiable, Hashable {
    let id: String
    /// Width divided by height.
    let aspect: Double
    let isVideo: Bool
    let duration: TimeInterval
    /// An animated image (a GIF): it plays full screen; grids mark it "GIF".
    var isAnimated = false
}

enum DeleteError: Error {
    /// The user tapped "Don't Allow" in the iOS dialog.
    case declined
}

/// The app's view of the photo library. PhotoKit lives behind it so logic can be tested with a fake.
protocol PhotoLibrary: AnyObject, Sendable {
    func accessLevel() -> AccessLevel
    func requestAccess() async -> AccessLevel
    func albums() -> [AlbumInfo]
    /// Newest first.
    func assets(inAlbum id: String) -> [AssetInfo]
    /// The assets with these ids, in the given order; ids no longer in the library are left out.
    func assets(withIDs ids: [String]) -> [AssetInfo]
    func fileSize(ofAsset id: String) -> Int64?
    /// Size of every asset in the album in one pass; values in `cached` are reused, not measured again.
    /// Stops early (partial result) when the current task is cancelled.
    func fileSizes(inAlbum id: String, cached: [String: Int64?]) -> [String: Int64?]
    func existingIDs(among ids: [String]) -> Set<String>
    /// Shows the iOS confirmation dialog. Throws `DeleteError.declined` when the user declines.
    /// Photos that cannot be deleted (shared or synced) are skipped. Returns the ids really deleted.
    func delete(_ ids: [String]) async throws -> [String]
}
