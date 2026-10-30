import CoreGraphics

/// A horizontal swipe on the tab bar or a page edge switches to the next or previous tab.
/// Tabs sit left to right as in the tab bar (Albums, Trash, Settings): a swipe to the left goes
/// to the tab on the right, a swipe to the right to the tab on the left.
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
        guard dx != 0 else { return tab }
        return AppModel.Tab(rawValue: tab.rawValue + (dx < 0 ? 1 : -1)) ?? tab
    }

    /// An edge swipe starts at an edge that has a tab behind it: the right edge when there is a
    /// tab on the right, the left edge when there is one on the left. (The left edge on a pushed
    /// album page is the system's back swipe.)
    static func startsAtEdge(x: CGFloat, width: CGFloat, on tab: AppModel.Tab) -> Bool {
        let hasLeft = tab.rawValue > 0
        let hasRight = tab.rawValue < AppModel.Tab.allCases.count - 1
        return (hasLeft && x < edgeWidth) || (hasRight && x > width - edgeWidth)
    }
}
