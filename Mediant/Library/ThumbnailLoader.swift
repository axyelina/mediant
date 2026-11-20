import AVFoundation
import Photos
import UIKit

/// Loads photo images and video player items through a caching PhotoKit image manager.
@MainActor
final class ThumbnailLoader {
    private let manager = PHCachingImageManager()
    private var assets: [String: PHAsset] = [:]

    /// A quick low-quality image first (when PhotoKit has one), then the full-quality image.
    /// Downloads from iCloud when needed. Ending the iteration cancels the request.
    func images(for id: String, target: CGSize,
                contentMode: PHImageContentMode = .aspectFill) -> AsyncStream<UIImage> {
        guard let asset = asset(for: id) else { return AsyncStream { $0.finish() } }
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        let scale = UIScreen.main.scale
        let pixels = CGSize(width: target.width * scale, height: target.height * scale)
        let manager = manager
        return AsyncStream { continuation in
            let requestID = manager.requestImage(for: asset, targetSize: pixels, contentMode: contentMode,
                                                 options: options) { image, info in
                if let image { continuation.yield(image) }
                let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !degraded { continuation.finish() }
            }
            continuation.onTermination = { _ in manager.cancelImageRequest(requestID) }
        }
    }

    /// A player item for a video; downloads it from iCloud when needed. Nil for a photo or a failed load.
    func playerItem(for id: String) async -> AVPlayerItem? {
        guard let asset = asset(for: id), asset.mediaType == .video else { return nil }
        let options = PHVideoRequestOptions()
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true
        let manager = manager
        let box = await withCheckedContinuation { (continuation: CheckedContinuation<ItemBox, Never>) in
            manager.requestPlayerItem(forVideo: asset, options: options) { item, _ in
                continuation.resume(returning: ItemBox(item: item))
            }
        }
        return box.item
    }

    /// The original file data of an image (a GIF to animate); downloads it from iCloud when
    /// needed. Nil for a video or a failed load.
    func imageData(for id: String) async -> Data? {
        guard let asset = asset(for: id), asset.mediaType == .image else { return nil }
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.version = .original
        options.isNetworkAccessAllowed = true
        let manager = manager
        return await withCheckedContinuation { (continuation: CheckedContinuation<Data?, Never>) in
            manager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                continuation.resume(returning: data)
            }
        }
    }

    /// Fetches the PHAssets for many ids in one query off the main actor, so cells don't each query.
    func prefetch(_ ids: [String]) async {
        let missing = ids.filter { assets[$0] == nil }
        guard !missing.isEmpty else { return }
        let fetched = await Self.fetch(missing)
        for asset in fetched.assets { assets[asset.localIdentifier] = asset }
    }

    private nonisolated static func fetch(_ ids: [String]) async -> AssetBox {
        var found: [PHAsset] = []
        PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil).enumerateObjects { asset, _, _ in
            found.append(asset)
        }
        return AssetBox(assets: found)
    }

    private func asset(for id: String) -> PHAsset? {
        if let cached = assets[id] { return cached }
        let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject
        assets[id] = asset
        return asset
    }
}

/// PHAsset is immutable but not marked Sendable.
private struct AssetBox: @unchecked Sendable {
    let assets: [PHAsset]
}

/// PhotoKit hands the player item over from its own queue; nothing touches it until it arrives.
private struct ItemBox: @unchecked Sendable {
    let item: AVPlayerItem?
}
