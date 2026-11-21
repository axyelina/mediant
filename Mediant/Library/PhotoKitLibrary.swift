import Photos

final class PhotoKitLibrary: PhotoLibrary {
    /// Albums hidden from the list: Hidden, "Recently Deleted" (raw value 1000000201), and albums
    /// whose photos cannot be deleted (iCloud shared, synced from a computer).
    private static let excludedSubtypes: Set<Int> = [
        PHAssetCollectionSubtype.smartAlbumAllHidden.rawValue, 1_000_000_201,
        PHAssetCollectionSubtype.albumCloudShared.rawValue,
        PHAssetCollectionSubtype.albumSyncedAlbum.rawValue,
        PHAssetCollectionSubtype.albumSyncedFaces.rawValue,
        PHAssetCollectionSubtype.albumSyncedEvent.rawValue,
    ]

    private static let pinnedSubtypes: [PHAssetCollectionSubtype: PinnedAlbum] = [
        .smartAlbumFavorites: .favorites, .smartAlbumRecentlyAdded: .recentlyAdded,
        .smartAlbumVideos: .videos, .smartAlbumScreenshots: .screenshots, .smartAlbumSelfPortraits: .selfies,
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
                        isAllPhotos: collection.assetCollectionSubtype == .smartAlbumUserLibrary,
                        // Only smart albums: a user's own album has subtype .albumRegular.
                        pinned: type == .smartAlbum ? Self.pinnedSubtypes[collection.assetCollectionSubtype] : nil))
                }
        }
        return orderedAlbums(result)
    }

    func assets(inAlbum id: String) -> [AssetInfo] {
        guard let collection = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [id], options: nil).firstObject else { return [] }
        let fetch = PHAsset.fetchAssets(in: collection, options: Self.newestFirst)
        return Self.infos(fetch)
    }

    func assets(withIDs ids: [String]) -> [AssetInfo] {
        guard !ids.isEmpty else { return [] }
        let byID = Dictionary(Self.infos(PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil))
            .map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return ids.compactMap { byID[$0] }
    }

    private static func infos(_ fetch: PHFetchResult<PHAsset>) -> [AssetInfo] {
        var result: [AssetInfo] = []
        result.reserveCapacity(fetch.count)
        fetch.enumerateObjects { asset, _, _ in
            let aspect = asset.pixelHeight > 0 ? Double(asset.pixelWidth) / Double(asset.pixelHeight) : 1
            result.append(AssetInfo(id: asset.localIdentifier, aspect: aspect,
                                    isVideo: asset.mediaType == .video, duration: asset.duration,
                                    isAnimated: asset.playbackStyle == .imageAnimated))
        }
        return result
    }

    func fileSize(ofAsset id: String) -> Int64? {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject else { return nil }
        return Self.size(of: asset)
    }

    func fileSizes(inAlbum id: String, cached: [String: Int64?]) -> [String: Int64?] {
        guard let collection = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [id], options: nil).firstObject else { return [:] }
        var result: [String: Int64?] = [:]
        PHAsset.fetchAssets(in: collection, options: nil).enumerateObjects { asset, _, stop in
            if Task.isCancelled {
                stop.pointee = true
                return
            }
            let assetID = asset.localIdentifier
            result[assetID] = cached[assetID] ?? Self.size(of: asset)
        }
        return result
    }

    /// PhotoKit has no public size API; "fileSize" on PHAssetResource is the only source.
    private static func size(of asset: PHAsset) -> Int64? {
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

    func delete(_ ids: [String]) async throws -> [String] {
        var deletable: [PHAsset] = []
        PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil).enumerateObjects { asset, _, _ in
            if asset.canPerform(.delete) { deletable.append(asset) }
        }
        guard !deletable.isEmpty else { return [] }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(deletable as NSArray)
            }
        } catch let error as PHPhotosError where error.code == .userCancelled {
            throw DeleteError.declined
        }
        return deletable.map(\.localIdentifier)
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

    func exportFile(ofAsset id: String, to directory: URL) async throws -> URL {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject
        else { throw CocoaError(.fileNoSuchFile) }
        let resources = PHAssetResource.assetResources(for: asset)
        // The current version first (edited, if the user edited it in Photos), else the original.
        let order: [PHAssetResourceType] = asset.mediaType == .video
            ? [.fullSizeVideo, .video] : [.fullSizePhoto, .photo]
        guard let resource = order.lazy.compactMap({ type in resources.first { $0.type == type } }).first
        else { throw CocoaError(.fileNoSuchFile) }
        let url = directory.appendingPathComponent(resource.originalFilename)
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        try await PHAssetResourceManager.default().writeData(for: resource, toFile: url, options: options)
        return url
    }
}
