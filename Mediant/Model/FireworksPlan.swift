import CoreGraphics
import Foundation

/// A small seeded random generator (SplitMix64): the same seed always gives the same numbers.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// The fireworks show after a tip: when each rocket leaves, where it flies and how big it bursts.
///
/// All positions are in canvas points. The view draws the plan and fires a haptic at each
/// `burstTime`. The same seed gives the same plan, so the plan is unit-tested.
struct FireworksPlan: Equatable {
    struct Rocket: Equatable {
        /// Seconds after the show starts.
        let launch: TimeInterval
        /// Seconds from the launch to the burst.
        let flight: TimeInterval
        let start: CGPoint
        let burst: CGPoint
        /// Sideways pull of the flight path, in points.
        let bend: CGFloat
        let radius: CGFloat
        /// Palette pair: the rocket index. The view takes it modulo its palette count.
        let pair: Int
        let isFinale: Bool

        var burstTime: TimeInterval { launch + flight }
    }

    /// Seconds a burst stays visible.
    static let burstLife: TimeInterval = 1.5

    private static let launchGap: TimeInterval = 0.38
    private static let finaleDelay: TimeInterval = 0.35
    private static let finaleRadius: CGFloat = 250
    /// Gap kept between a burst and the screen edge.
    private static let edgeMargin: CGFloat = 10
    private static let topMargin: CGFloat = 8

    let rockets: [Rocket]

    /// When the last burst has faded.
    var duration: TimeInterval {
        (rockets.map(\.burstTime).max() ?? 0) + Self.burstLife
    }

    init(size: TipSize, canvas: CGSize, seed: UInt64) {
        var random = SeededGenerator(seed: seed)
        let count: Int
        switch size {
        case .small: count = 1
        case .medium: count = 2
        case .large: count = 3
        case .huge: count = 5
        }
        // A burst wider than the screen could not stay on it.
        let widest = canvas.width / 2 - Self.edgeMargin
        let lowest = 0.45 * canvas.height

        var rockets: [Rocket] = []
        for index in 0..<count {
            let wanted = count == 1 ? CGFloat.random(in: 190...220, using: &random)
                                    : CGFloat.random(in: 130...175, using: &random)
            let radius = min(wanted, widest)
            let startX = CGFloat.random(in: 0.3...0.7, using: &random) * canvas.width
            let burstX = CGFloat.random(in: (radius + Self.edgeMargin)...(canvas.width - radius - Self.edgeMargin),
                                        using: &random)
            let highest = max(0.2 * canvas.height, min(radius + Self.topMargin, lowest))
            let burstY = CGFloat.random(in: highest...lowest, using: &random)
            rockets.append(Rocket(
                launch: Double(index) * Self.launchGap,
                flight: Double.random(in: 0.75...0.95, using: &random),
                start: CGPoint(x: startX, y: canvas.height + 10),
                burst: CGPoint(x: burstX, y: burstY),
                bend: CGFloat.random(in: -90...90, using: &random),
                radius: radius, pair: index, isFinale: false))
        }
        if size == .huge {
            let radius = min(Self.finaleRadius, widest)
            let burstY = max(0.36 * canvas.height, min(radius + Self.topMargin, lowest))
            rockets.append(Rocket(
                launch: Double(count - 1) * Self.launchGap + Self.finaleDelay,
                flight: Double.random(in: 0.75...0.95, using: &random),
                start: CGPoint(x: canvas.width / 2, y: canvas.height + 10),
                burst: CGPoint(x: canvas.width / 2, y: burstY),
                bend: 0, radius: radius, pair: count, isFinale: true))
        }
        self.rockets = rockets
    }
}
