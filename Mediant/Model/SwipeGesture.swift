import CoreGraphics

/// What a finished drag on the swipe screen means. The bigger axis decides (a tie counts as
/// vertical): up = trash, down = keep. Sideways only browses, with no decision: left = the next
/// photo, right = the previous one.
/// A drag counts past `distance`, or as a fling whose predicted end is past `flingDistance`.
enum SwipeGesture {
    enum Outcome: Equatable { case trash, keep, next, previous, none }

    static let distance: CGFloat = 90
    static let flingDistance: CGFloat = 160

    static func outcome(translation: CGSize, predictedEnd: CGSize) -> Outcome {
        if abs(translation.height) >= abs(translation.width) {
            let dy = value(translation.height, predicted: predictedEnd.height)
            return dy < 0 ? .trash : dy > 0 ? .keep : .none
        }
        let dx = value(translation.width, predicted: predictedEnd.width)
        return dx < 0 ? .next : dx > 0 ? .previous : .none
    }

    private static func value(_ moved: CGFloat, predicted: CGFloat) -> CGFloat {
        abs(moved) > distance ? moved : abs(predicted) > flingDistance ? predicted : 0
    }
}
