import Testing
@testable import Mediant

struct AlbumOrderTests {
    func album(_ title: String, _ pinned: PinnedAlbum? = nil, allPhotos: Bool = false) -> AlbumInfo {
        AlbumInfo(id: title, title: title, count: 1, coverAssetID: nil, isAllPhotos: allPhotos, pinned: pinned)
    }

    @Test func pinnedAlbumsComeFirstInTheirOrder() {
        let albums = [
            album("Selfies", .selfies), album("Beach"), album("Videos", .videos),
            album("Screenshots", .screenshots), album("Favorites", .favorites),
            album("Recently Added", .recentlyAdded),
        ]
        #expect(orderedAlbums(albums).map(\.title)
                == ["Favorites", "Recently Added", "Videos", "Screenshots", "Selfies", "Beach"])
    }

    @Test func recentsLeadsTheOtherAlbums() {
        let albums = [album("Zoo"), album("Recents", allPhotos: true), album("Videos", .videos), album("Art")]
        #expect(orderedAlbums(albums).map(\.title) == ["Videos", "Recents", "Art", "Zoo"])
    }

    @Test func otherAlbumsAreByTitle() {
        let albums = [album("trip 10"), album("Beach"), album("trip 2")]
        #expect(orderedAlbums(albums).map(\.title) == ["Beach", "trip 2", "trip 10"])
    }

    @Test func missingPinnedAlbumsAreSkipped() {
        let albums = [album("Art"), album("Selfies", .selfies), album("Favorites", .favorites)]
        #expect(orderedAlbums(albums).map(\.title) == ["Favorites", "Selfies", "Art"])
    }
}
