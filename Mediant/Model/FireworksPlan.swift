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
        /// Sideways pull of the flight path, in points (up to 0.17 of the canvas width).
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
    /// Share of the canvas width (the sizes were drawn on a 540 px canvas for a 393 pt phone).
    /// Its rim (1.25 × 0.46 W) is wider than the screen, so the finale's outer dots leave the sides.
    private static let finaleRadius: CGFloat = 0.46
    /// The rim dots fly out to this times the radius (`FireworksView`): the gap a burst center
    /// keeps from the side and top edges.
    static let rimReach: CGFloat = 1.25

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
        let lowest = 0.45 * canvas.height

        var rockets: [Rocket] = []
        for index in 0..<count {
            let radius = (count == 1 ? CGFloat.random(in: 0.35...0.41, using: &random)
                                     : CGFloat.random(in: 0.24...0.32, using: &random)) * canvas.width
            let startX = CGFloat.random(in: 0.3...0.7, using: &random) * canvas.width
            // A burst wider than the screen (a single rocket above 0.4 W) goes to the middle.
            let side = min(Self.rimReach * radius, canvas.width / 2)
            let burstX = CGFloat.random(in: side...(canvas.width - side), using: &random)
            let highest = max(0.2 * canvas.height, min(Self.rimReach * radius, lowest))
            let burstY = CGFloat.random(in: highest...lowest, using: &random)
            rockets.append(Rocket(
                launch: Double(index) * Self.launchGap,
                flight: Double.random(in: 0.75...0.95, using: &random),
                start: CGPoint(x: startX, y: canvas.height + 10),
                burst: CGPoint(x: burstX, y: burstY),
                bend: CGFloat.random(in: -0.17...0.17, using: &random) * canvas.width,
                radius: radius, pair: index, isFinale: false))
        }
        if size == .huge {
            let radius = Self.finaleRadius * canvas.width
            let burstY = max(0.36 * canvas.height, min(Self.rimReach * radius, lowest))
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
