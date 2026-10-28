import Foundation
@testable import Mediant

/// In-memory photo library for unit tests.
final class FakePhotoLibrary: PhotoLibrary, @unchecked Sendable {
    var level: AccessLevel = .full
    var albumList: [AlbumInfo] = []
    var assetsByAlbum: [String: [AssetInfo]] = [:]
    var sizes: [String: Int64] = [:]
    var deleteError: Error?
    private(set) var deleted: [String] = []
    private(set) var singleSizeCalls = 0
    private(set) var batchSizeCalls = 0

    func accessLevel() -> AccessLevel { level }
    func requestAccess() async -> AccessLevel { level }
    func albums() -> [AlbumInfo] { albumList }
    func assets(inAlbum id: String) -> [AssetInfo] { assetsByAlbum[id] ?? [] }
    func fileSize(ofAsset id: String) -> Int64? {
        singleSizeCalls += 1
        return sizes[id]
    }

    func fileSizes(inAlbum id: String, cached: [String: Int64?]) -> [String: Int64?] {
        batchSizeCalls += 1
        var result: [String: Int64?] = [:]
        for asset in assets(inAlbum: id) { result[asset.id] = cached[asset.id] ?? sizes[asset.id] }
        return result
    }

    func existingIDs(among ids: [String]) -> Set<String> {
        let all = Set(assetsByAlbum.values.flatMap { $0.map(\.id) })
        return Set(ids).intersection(all)
    }

    func delete(_ ids: [String]) async throws {
        if let deleteError { throw deleteError }
        deleted += ids
    }

    /// Adds an album whose assets have the given sizes (nil = unknown size).
    func addAlbum(_ id: String, isAllPhotos: Bool = false, assets: [(String, Int64?)]) {
        albumList.append(AlbumInfo(id: id, title: id, count: assets.count,
                                   coverAssetID: assets.first?.0, isAllPhotos: isAllPhotos))
        assetsByAlbum[id] = assets.map { AssetInfo(id: $0.0, aspect: 0.75, isVideo: false, duration: 0) }
        for (assetID, size) in assets { sizes[assetID] = size }
    }
}
