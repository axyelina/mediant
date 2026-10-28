import Photos
import UIKit

/// Loads photo images through a caching PhotoKit image manager.
@MainActor
final class ThumbnailLoader {
    private let manager = PHCachingImageManager()
    private var assets: [String: PHAsset] = [:]

    func image(for id: String, target: CGSize, contentMode: PHImageContentMode = .aspectFill) async -> UIImage? {
        guard let asset = asset(for: id) else { return nil }
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        let scale = UIScreen.main.scale
        let pixels = CGSize(width: target.width * scale, height: target.height * scale)
        let manager = manager
        let request = RequestBox()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                request.id = manager.requestImage(for: asset, targetSize: pixels, contentMode: contentMode,
                                                  options: options) { image, _ in
                    continuation.resume(returning: image)
                }
            }
        } onCancel: {
            if let id = request.id { manager.cancelImageRequest(id) }
        }
    }

    private func asset(for id: String) -> PHAsset? {
        if let cached = assets[id] { return cached }
        let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject
        assets[id] = asset
        return asset
    }
}

/// Holds a request id that the cancel handler reads from another thread.
private final class RequestBox: @unchecked Sendable {
    private let lock = NSLock()
    private var value: PHImageRequestID?

    var id: PHImageRequestID? {
        get { lock.withLock { value } }
        set { lock.withLock { value = newValue } }
    }
}
