import CoreGraphics
import Testing
@testable import Mediant

struct TabSwipeTests {
    func swipe(_ dx: CGFloat, _ dy: CGFloat = 0, predicted: CGFloat? = nil, from tab: AppModel.Tab) -> AppModel.Tab {
        TabSwipe.target(translation: CGSize(width: dx, height: dy),
                        predictedEnd: CGSize(width: predicted ?? dx, height: dy), from: tab)
    }

    @Test func swipeLeftGoesFromAlbumsToTrash() {
        #expect(swipe(-80, from: .albums) == .trash)
    }

    @Test func swipeRightGoesFromTrashToAlbums() {
        #expect(swipe(80, from: .trash) == .albums)
    }

    @Test func swipeLeftGoesFromTrashToSettings() {
        #expect(swipe(-80, from: .trash) == .settings)
    }

    @Test func swipeRightGoesFromSettingsToTrash() {
        #expect(swipe(80, from: .settings) == .trash)
    }

    @Test func swipePastTheEndStays() {
        #expect(swipe(80, from: .albums) == .albums)
        #expect(swipe(-80, from: .settings) == .settings)
    }

    @Test func shortSlowSwipeStays() {
        #expect(swipe(-30, from: .albums) == .albums)
    }

    @Test func shortFlingSwitches() {
        #expect(swipe(-30, predicted: -200, from: .albums) == .trash)
    }

    @Test func mostlyVerticalDragStays() {
        #expect(swipe(-80, 120, from: .albums) == .albums)
    }

    @Test func edgeSwipeStartsAtAnEdgeThatHasATabBehindIt() {
        // Tabs left to right: Albums, Trash, Settings. An edge with no tab behind it does nothing.
        #expect(TabSwipe.startsAtEdge(x: 380, width: 393, on: .albums))
        #expect(!TabSwipe.startsAtEdge(x: 10, width: 393, on: .albums))
        #expect(!TabSwipe.startsAtEdge(x: 200, width: 393, on: .albums))
        #expect(TabSwipe.startsAtEdge(x: 10, width: 393, on: .trash))
        #expect(TabSwipe.startsAtEdge(x: 380, width: 393, on: .trash))
        #expect(!TabSwipe.startsAtEdge(x: 200, width: 393, on: .trash))
        #expect(TabSwipe.startsAtEdge(x: 10, width: 393, on: .settings))
        #expect(!TabSwipe.startsAtEdge(x: 380, width: 393, on: .settings))
    }
}
