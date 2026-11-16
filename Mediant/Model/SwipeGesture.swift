import CoreGraphics

/// What a finished drag on the swipe screen means. The bigger axis decides (a tie counts as
/// vertical): up = trash, down = keep, right = back to the album, left = nothing.
/// A drag counts past `distance`, or as a fling whose predicted end is past `flingDistance`.
enum SwipeGesture {
    enum Outcome: Equatable { case trash, keep, back, none }

    static let distance: CGFloat = 90
    static let flingDistance: CGFloat = 160

    static func outcome(translation: CGSize, predictedEnd: CGSize) -> Outcome {
        if abs(translation.height) >= abs(translation.width) {
            let dy = value(translation.height, predicted: predictedEnd.height)
            return dy < 0 ? .trash : dy > 0 ? .keep : .none
        }
        return value(translation.width, predicted: predictedEnd.width) > 0 ? .back : .none
    }

    private static func value(_ moved: CGFloat, predicted: CGFloat) -> CGFloat {
        abs(moved) > distance ? moved : abs(predicted) > flingDistance ? predicted : 0
    }
}
