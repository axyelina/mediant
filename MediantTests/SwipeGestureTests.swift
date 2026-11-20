import CoreGraphics
import Testing
@testable import Mediant

struct SwipeGestureTests {
    func outcome(_ dx: CGFloat, _ dy: CGFloat, predicted: CGSize? = nil) -> SwipeGesture.Outcome {
        SwipeGesture.outcome(translation: CGSize(width: dx, height: dy),
                             predictedEnd: predicted ?? CGSize(width: dx, height: dy))
    }

    @Test func upPastThresholdTrashes() {
        #expect(outcome(0, -100) == .trash)
    }

    @Test func downPastThresholdKeeps() {
        #expect(outcome(0, 100) == .keep)
    }

    @Test func shortFastFlingUpTrashes() {
        #expect(outcome(0, -40, predicted: CGSize(width: 0, height: -200)) == .trash)
    }

    @Test func shortFastFlingDownKeeps() {
        #expect(outcome(0, 40, predicted: CGSize(width: 0, height: 200)) == .keep)
    }

    @Test func shortSlowDragDoesNothing() {
        #expect(outcome(0, 40, predicted: CGSize(width: 0, height: 60)) == .none)
    }

    @Test func rightSwipeShowsPrevious() {
        #expect(outcome(100, 10) == .previous)
        #expect(outcome(40, 0, predicted: CGSize(width: 200, height: 0)) == .previous)
    }

    @Test func leftSwipeShowsNext() {
        #expect(outcome(-100, 10) == .next)
        #expect(outcome(-40, 0, predicted: CGSize(width: -200, height: 0)) == .next)
    }

    @Test func shortSlowSideDragDoesNothing() {
        #expect(outcome(40, 0, predicted: CGSize(width: 60, height: 0)) == .none)
        #expect(outcome(-40, 0, predicted: CGSize(width: -60, height: 0)) == .none)
    }

    @Test func diagonalUsesBiggerAxis() {
        #expect(outcome(60, -100) == .trash)
        #expect(outcome(100, -60) == .previous)
        // A tie counts as vertical.
        #expect(outcome(100, -100) == .trash)
    }
}
