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
}

struct AssetInfo: Identifiable, Hashable {
    let id: String
    /// Width divided by height.
    let aspect: Double
    let isVideo: Bool
    let duration: TimeInterval
}

/// The app's view of the photo library. PhotoKit lives behind it so logic can be tested with a fake.
protocol PhotoLibrary: AnyObject, Sendable {
    func accessLevel() -> AccessLevel
    func requestAccess() async -> AccessLevel
    func albums() -> [AlbumInfo]
    /// Newest first.
    func assets(inAlbum id: String) -> [AssetInfo]
    func fileSize(ofAsset id: String) -> Int64?
    func existingIDs(among ids: [String]) -> Set<String>
    /// Shows the iOS confirmation dialog; throws when the user declines.
    func delete(_ ids: [String]) async throws
}
