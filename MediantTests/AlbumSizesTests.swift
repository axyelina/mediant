import Foundation
import Testing
@testable import Mediant

@MainActor
struct AlbumSizesTests {
    let library = FakePhotoLibrary()
    let cacheURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("sizes-\(UUID().uuidString).json")

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

    @Test func refreshMarksSizesMeasured() async {
        library.addAlbum("x", assets: [("a", 100)])
        let sizes = AlbumSizes(library: library)
        #expect(!sizes.isMeasured("x"))
        #expect(!sizes.isTotalMeasured)
        await sizes.refresh(library.albums())
        #expect(sizes.isMeasured("x"))
        #expect(sizes.isTotalMeasured)
    }

    @Test func startsWithCachedSizesNotMeasured() async {
        library.addAlbum("all", isAllPhotos: true, assets: [("a", 100), ("b", 200)])
        library.addAlbum("mine", assets: [("a", 100)])
        await AlbumSizes(library: library, cacheURL: cacheURL).refresh(library.albums())

        let sizes = AlbumSizes(library: library, cacheURL: cacheURL)
        #expect(sizes.size(of: "mine") == 100)
        #expect(sizes.total == 300)
        #expect(!sizes.isMeasured("mine"))
        #expect(!sizes.isTotalMeasured)
    }

    @Test func refreshReplacesCachedSizes() async {
        library.addAlbum("x", assets: [("a", 100)])
        await AlbumSizes(library: library, cacheURL: cacheURL).refresh(library.albums())
        library.sizes["a"] = 700

        let sizes = AlbumSizes(library: library, cacheURL: cacheURL)
        await sizes.refresh(library.albums())
        #expect(sizes.size(of: "x") == 700)
        #expect(sizes.isMeasured("x"))
    }

    @Test func cacheDropsRemovedAlbums() async {
        library.addAlbum("x", assets: [("a", 100)])
        library.addAlbum("y", assets: [("b", 50)])
        let first = AlbumSizes(library: library, cacheURL: cacheURL)
        await first.refresh(library.albums())
        library.albumList.removeAll { $0.id == "y" }
        await first.refresh(library.albums())

        let sizes = AlbumSizes(library: library, cacheURL: cacheURL)
        #expect(sizes.size(of: "y") == nil)
        #expect(sizes.total == 100)
    }
}
