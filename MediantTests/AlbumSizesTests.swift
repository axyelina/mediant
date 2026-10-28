import Testing
@testable import Mediant

@MainActor
struct AlbumSizesTests {
    let library = FakePhotoLibrary()

    @Test func sumsAssetSizes() async {
        library.addAlbum("x", assets: [("a", 100), ("b", 200)])
        let sizes = AlbumSizes(library: library)
        await sizes.refresh(library.albums())
        #expect(sizes.size(of: "x") == 300)
    }

    @Test func ignoresMissingSizes() async {
        library.addAlbum("x", assets: [("a", 100), ("b", nil)])
        library.addAlbum("y", assets: [("c", nil)])
        let sizes = AlbumSizes(library: library)
        await sizes.refresh(library.albums())
        #expect(sizes.size(of: "x") == 100)
        #expect(sizes.size(of: "y") == nil)
    }

    @Test func totalUsesAllPhotosAlbum() async {
        library.addAlbum("all", isAllPhotos: true, assets: [("a", 100), ("b", 200), ("c", 300)])
        library.addAlbum("mine", assets: [("a", 100)])
        let sizes = AlbumSizes(library: library)
        await sizes.refresh(library.albums())
        #expect(sizes.total == 600)
    }

    @Test func totalSumsAlbumsWithoutAllPhotos() async {
        library.addAlbum("x", assets: [("a", 100)])
        library.addAlbum("y", assets: [("b", 50)])
        let sizes = AlbumSizes(library: library)
        await sizes.refresh(library.albums())
        #expect(sizes.total == 150)
    }

    @Test func usesOneBatchedQueryPerAlbum() async {
        library.addAlbum("x", assets: [("a", 100), ("b", 200)])
        library.addAlbum("y", assets: [("c", 50)])
        let sizes = AlbumSizes(library: library)
        await sizes.refresh(library.albums())
        #expect(library.singleSizeCalls == 0)
        #expect(library.batchSizeCalls == 2)
    }

    @Test func unknownAlbumHasNoSize() {
        let sizes = AlbumSizes(library: library)
        #expect(sizes.size(of: "nope") == nil)
        #expect(sizes.total == nil)
    }
}
