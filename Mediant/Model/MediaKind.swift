/// What a library item is, for texts that name it ("the photo", "the video", "the GIF").
enum MediaKind: Equatable {
    case photo, video, gif

    init(_ asset: AssetInfo) {
        self = asset.isVideo ? .video : asset.isAnimated ? .gif : .photo
    }
}
