import CoreGraphics

/// A horizontal swipe on the tab bar or a page edge switches Albums ↔ Trash.
/// Tabs sit left to right as in the tab bar: a swipe to the left goes to Trash, to the right to Albums.
enum TabSwipe {
    /// Width of the page edge where an edge swipe may start.
    static let edgeWidth: CGFloat = 24
    private static let distance: CGFloat = 50
    private static let flingDistance: CGFloat = 150

    /// The tab a finished drag leads to. Short slow drags and mostly vertical ones change nothing.
    static func target(translation: CGSize, predictedEnd: CGSize, from tab: AppModel.Tab) -> AppModel.Tab {
        guard abs(translation.width) > abs(translation.height) else { return tab }
        let dx = abs(translation.width) > distance ? translation.width
            : abs(predictedEnd.width) > flingDistance ? predictedEnd.width : 0
        if dx < 0, tab == .albums { return .trash }
        if dx > 0, tab == .trash { return .albums }
        return tab
    }

    /// An edge swipe starts at the edge on the side of the other tab: the right edge on Albums, the
    /// left edge on Trash. (The left edge on a pushed album page is the system's back swipe.)
    static func startsAtEdge(x: CGFloat, width: CGFloat, on tab: AppModel.Tab) -> Bool {
        tab == .albums ? x > width - edgeWidth : x < edgeWidth
    }
}
