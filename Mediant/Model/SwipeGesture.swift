import CoreGraphics

/// What a finished drag on the swipe screen means. The bigger axis decides (a tie counts as
/// vertical): up = trash, down = keep. Sideways only browses, with no decision: left = the next
/// photo, right = the previous one. A right swipe that starts at the left screen edge goes back
/// to the album instead (as the iOS back swipe).
/// A drag counts past `distance`, or as a fling whose predicted end is past `flingDistance`.
enum SwipeGesture {
    enum Outcome: Equatable { case trash, keep, next, previous, back, none }

    static let distance: CGFloat = 90
    static let flingDistance: CGFloat = 160
    /// Width of the left screen edge where the back swipe starts (the same as the tab edge swipe).
    static let backEdgeWidth: CGFloat = TabSwipe.edgeWidth

    /// True when a drag that starts at `x` is a back swipe if it goes right.
    static func startsAtBackEdge(x: CGFloat) -> Bool { x < backEdgeWidth }

    static func outcome(startX: CGFloat, translation: CGSize, predictedEnd: CGSize) -> Outcome {
        if abs(translation.height) >= abs(translation.width) {
            let dy = value(translation.height, predicted: predictedEnd.height)
            return dy < 0 ? .trash : dy > 0 ? .keep : .none
        }
        let dx = value(translation.width, predicted: predictedEnd.width)
        if dx > 0 { return startsAtBackEdge(x: startX) ? .back : .previous }
        return dx < 0 ? .next : .none
    }

    private static func value(_ moved: CGFloat, predicted: CGFloat) -> CGFloat {
        abs(moved) > distance ? moved : abs(predicted) > flingDistance ? predicted : 0
    }
}
