import SwiftUI

extension View {
    /// A light band that moves across the view while `active`: the value shown is not final yet.
    func shimmering(_ active: Bool) -> some View {
        modifier(Shimmer(active: active))
    }
}

private struct Shimmer: ViewModifier {
    let active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let period = 1.4

    func body(content: Content) -> some View {
        if active {
            TimelineView(.animation(paused: reduceMotion)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                // The band center moves from -0.5 to 1.5, so it enters and leaves fully.
                let center = reduceMotion ? 0.5 : time.truncatingRemainder(dividingBy: Self.period) / Self.period * 2 - 0.5
                content.mask {
                    LinearGradient(colors: [.black.opacity(0.4), .black, .black.opacity(0.4)],
                                   startPoint: UnitPoint(x: center - 0.5, y: 0.5),
                                   endPoint: UnitPoint(x: center + 0.5, y: 0.5))
                }
            }
        } else {
            content
        }
    }
}
