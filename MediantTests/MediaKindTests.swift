import Testing
@testable import Mediant

struct MediaKindTests {
    func asset(video: Bool = false, animated: Bool = false) -> AssetInfo {
        AssetInfo(id: "a", aspect: 1, isVideo: video, duration: video ? 5 : 0, isAnimated: animated)
    }

    @Test func aStillImageIsAPhoto() {
        #expect(MediaKind(asset()) == .photo)
    }

    @Test func aVideoIsAVideo() {
        #expect(MediaKind(asset(video: true)) == .video)
    }

    @Test func anAnimatedImageIsAGIF() {
        #expect(MediaKind(asset(animated: true)) == .gif)
    }
}
