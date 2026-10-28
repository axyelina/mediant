import Photos

final class PhotoKitLibrary: PhotoLibrary {
    /// Smart albums that are hidden from the list. Raw value 1000000201 is "Recently Deleted".
    private static let excludedSubtypes: Set<Int> = [
        PHAssetCollectionSubtype.smartAlbumAllHidden.rawValue, 1_000_000_201,
    ]

    func accessLevel() -> AccessLevel {
        Self.level(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    func requestAccess() async -> AccessLevel {
        Self.level(await PHPhotoLibrary.requestAuthorization(for: .readWrite))
    }

    func albums() -> [AlbumInfo] {
        var result: [AlbumInfo] = []
        for type in [PHAssetCollectionType.smartAlbum, .album] {
            PHAssetCollection.fetchAssetCollections(with: type, subtype: .any, options: nil)
                .enumerateObjects { collection, _, _ in
                    guard !Self.excludedSubtypes.contains(collection.assetCollectionSubtype.rawValue) else { return }
                    let assets = PHAsset.fetchAssets(in: collection, options: Self.newestFirst)
                    guard assets.count > 0 else { return }
                    result.append(AlbumInfo(
                        id: collection.localIdentifier,
                        title: collection.localizedTitle ?? "",
                        count: assets.count,
                        coverAssetID: assets.firstObject?.localIdentifier,
                        isAllPhotos: collection.assetCollectionSubtype == .smartAlbumUserLibrary))
                }
        }
        return result.sorted { lhs, rhs in
            if lhs.isAllPhotos != rhs.isAllPhotos { return lhs.isAllPhotos }
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
    }

    func assets(inAlbum id: String) -> [AssetInfo] {
        guard let collection = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [id], options: nil).firstObject else { return [] }
        let fetch = PHAsset.fetchAssets(in: collection, options: Self.newestFirst)
        var result: [AssetInfo] = []
        result.reserveCapacity(fetch.count)
        fetch.enumerateObjects { asset, _, _ in
            let aspect = asset.pixelHeight > 0 ? Double(asset.pixelWidth) / Double(asset.pixelHeight) : 1
            result.append(AssetInfo(id: asset.localIdentifier, aspect: aspect,
                                    isVideo: asset.mediaType == .video, duration: asset.duration))
        }
        return result
    }

    func fileSize(ofAsset id: String) -> Int64? {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject else { return nil }
        // PhotoKit has no public size API; "fileSize" on PHAssetResource is the only source.
        let sizes = PHAssetResource.assetResources(for: asset)
            .compactMap { ($0.value(forKey: "fileSize") as? NSNumber)?.int64Value }
        return sizes.isEmpty ? nil : sizes.reduce(0, +)
    }

    func existingIDs(among ids: [String]) -> Set<String> {
        var found = Set<String>()
        PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
            .enumerateObjects { asset, _, _ in found.insert(asset.localIdentifier) }
        return found
    }

    func delete(_ ids: [String]) async throws {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets)
        }
    }

    private static var newestFirst: PHFetchOptions {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return options
    }

    private static func level(_ status: PHAuthorizationStatus) -> AccessLevel {
        switch status {
        case .authorized: .full
        case .limited: .limited
        case .notDetermined: .notDetermined
        default: .denied
        }
    }
}
