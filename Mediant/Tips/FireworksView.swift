import SwiftUI

/// The fireworks after a tip: one show over the whole app, a haptic tap at each burst.
///
/// Draws `FireworksPlan` the way the prototype `07-fireworks.html` (look A) does. The prototype
/// was drawn on a 540 px canvas for a 393 pt phone, so its sizes are scaled by `width / 540`.
/// With Reduce Motion on it draws nothing and taps one haptic; `TipButtons` shows a glow. The
/// haptic lives here because this view is always there, while the tapped place may be gone.
struct FireworksView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var show: Show?
    @State private var canvas: CGSize = .zero
    @State private var burstCount = 0
    @State private var finaleCount = 0
    @State private var quietCount = 0

    var body: some View {
        ZStack {
            if let show, !reduceMotion {
                let palette = colorScheme == .light ? Palette.light : Palette.dark
                TimelineView(.animation(minimumInterval: 1.0 / 60)) { timeline in
                    Canvas { context, _ in
                        show.draw(in: &context, at: timeline.date.timeIntervalSince(show.start), palette: palette)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGSize.self) { $0.size } action: { canvas = $0 }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        // `celebration` is never cleared and its id grows, so every change is a new tip.
        .onChange(of: model.tips.celebration) { _, celebration in
            guard let celebration else { return }
            if reduceMotion {
                quietCount += 1
                return
            }
            // The plan needs a real canvas (it traps below about 111 pt).
            guard canvas.width >= 200, canvas.height >= 200 else { return }
            let seed = UInt64.random(in: 0...UInt64.max)
            show = Show(id: celebration.id, plan: FireworksPlan(size: celebration.size, canvas: canvas, seed: seed),
                        seed: seed, width: canvas.width, start: .now)
        }
        // Turned on during a show: the show ends at once, with its remaining haptics.
        .onChange(of: reduceMotion) { _, on in
            if on { show = nil }
        }
        .task(id: show?.id) { await play() }
        .sensoryFeedback(.impact(weight: .medium), trigger: burstCount)
        .sensoryFeedback(.impact(weight: .heavy), trigger: finaleCount)
        .sensoryFeedback(.impact, trigger: quietCount)
    }

    /// Taps a haptic at each burst, then ends the show. A new show cancels the old one.
    private func play() async {
        guard let show else { return }
        for rocket in show.plan.rockets.sorted(by: { $0.burstTime < $1.burstTime }) {
            guard await sleep(until: rocket.burstTime, of: show) else { return }
            // A burst that is long gone (e.g. the app was in the background) gets no haptic, so
            // missed bursts do not tap in a row.
            guard show.start.addingTimeInterval(rocket.burstTime).timeIntervalSinceNow > -Self.hapticLateness
            else { continue }
            if rocket.isFinale { finaleCount += 1 } else { burstCount += 1 }
        }
        guard await sleep(until: show.plan.duration, of: show) else { return }
        self.show = nil
    }

    /// False when the task was cancelled.
    private func sleep(until time: TimeInterval, of show: Show) async -> Bool {
        let wait = show.start.addingTimeInterval(time).timeIntervalSinceNow
        if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
        return !Task.isCancelled
    }

    /// Seconds after its burst that a haptic still fires.
    private static let hapticLateness: TimeInterval = 0.1
}

private struct Palette {
    /// One burst color with everything drawn from it, built once.
    struct Ink {
        let color: GraphicsContext.Shading
        /// A streak: clear at its inner end, brightest outside.
        let streak: Gradient
        /// A streak in the blurred glow pass, where the taper does not show.
        let glow: GraphicsContext.Shading

        init(_ color: Color) {
            self.color = .color(color)
            streak = Gradient(stops: [.init(color: color.opacity(0), location: 0),
                                      .init(color: color.opacity(0.67), location: 0.55),
                                      .init(color: color, location: 1)])
            glow = .color(color.opacity(0.6))
        }
    }

    let pairs: [(Ink, Ink)]
    let trail: GraphicsContext.Shading
    let star: GraphicsContext.Shading
    let glows: Bool

    init(pairs: [(Color, Color)], trail: Color, star: Color, glows: Bool) {
        self.pairs = pairs.map { (Ink($0.0), Ink($0.1)) }
        self.trail = .color(trail)
        self.star = .color(star)
        self.glows = glows
    }

    static let dark = Palette(
        pairs: [(.hex(0xff5c93), .hex(0xffd1e3)), (.hex(0xc2184e), .white),
                (.hex(0xffd1e3), .hex(0xff5c93)), (.white, .hex(0xc2184e))],
        trail: .hex(0xffd1e3), star: .white, glows: true)

    static let light = Palette(
        pairs: [(.hex(0xc2184e), .hex(0xff5c93)), (.hex(0x470112), .hex(0xff5c93)),
                (.hex(0xff5c93), .hex(0x75013d))],
        trail: .hex(0xc2184e), star: .hex(0xc2184e), glows: false)
}

private extension Color {
    static func hex(_ value: UInt32) -> Color {
        Color(red: Double(value >> 16 & 0xff) / 255, green: Double(value >> 8 & 0xff) / 255,
              blue: Double(value & 0xff) / 255)
    }
}

/// One show: the plan plus the random details of every burst, fixed when the show starts.
private struct Show {
    struct Streak { let angle, length, width: CGFloat; let second: Bool }
    struct Dot { let angle, distance, radius, phase: CGFloat; let second: Bool }
    struct Twinkle { let angle, distance, height, delay, phase: CGFloat }
    struct Burst { let streaks: [Streak]; let dots: [Dot]; let twinkles: [Twinkle] }

    let id: Int
    let plan: FireworksPlan
    let start: Date
    /// Points per prototype pixel.
    let scale: CGFloat
    let bursts: [Burst]

    init(id: Int, plan: FireworksPlan, seed: UInt64, width: CGFloat, start: Date) {
        let scale = width / 540
        self.id = id
        self.plan = plan
        self.start = start
        self.scale = scale
        var random = SeededGenerator(seed: seed &+ 1)
        func rnd(_ range: ClosedRange<CGFloat>) -> CGFloat { .random(in: range, using: &random) }
        bursts = plan.rockets.map { rocket in
            let big = rocket.isFinale, radius = rocket.radius
            let streakCount = big ? 72 : 48
            let streaks = (0..<streakCount).map { i in
                Streak(angle: CGFloat(i) / CGFloat(streakCount) * 2 * .pi + rnd(-0.05...0.05),
                       length: rnd(0.75...1) * radius, width: rnd(2.2...4) * scale * (big ? 1.3 : 1),
                       second: i % 2 == 1)
            }
            let dots = (0..<(big ? 60 : 36)).map { i in
                Dot(angle: rnd(0...(2 * .pi)), distance: rnd(1.02...1.25) * radius,
                    radius: rnd(2...4.5) * scale, phase: rnd(0...6), second: i % 2 == 1)
            }
            let twinkles = (0..<(big ? 12 : 7)).map { _ in
                Twinkle(angle: rnd(0...(2 * .pi)), distance: rnd(0.3...1.1) * radius,
                        height: rnd(10...20) * scale, delay: rnd(0.25...0.7), phase: rnd(0...6))
            }
            return Burst(streaks: streaks, dots: dots, twinkles: twinkles)
        }
    }

    /// Draws the show `time` seconds after its start. Glow in dark mode: a blurred copy under
    /// the sharp drawing, both added onto each other (the prototype's `lighter` and shadow blur).
    func draw(in context: inout GraphicsContext, at time: TimeInterval, palette: Palette) {
        guard time >= 0, time < plan.duration else { return }
        if palette.glows {
            context.blendMode = .plusLighter
            context.drawLayer { glow in
                glow.addFilter(.blur(radius: 6 * scale))
                glow.blendMode = .plusLighter
                drawRockets(in: &glow, at: time, palette: palette, glow: true)
            }
        }
        drawRockets(in: &context, at: time, palette: palette, glow: false)
    }

    private func drawRockets(in context: inout GraphicsContext, at time: TimeInterval, palette: Palette,
                             glow: Bool) {
        for (rocket, burst) in zip(plan.rockets, bursts) {
            let age = time - rocket.launch
            guard age >= 0 else { continue }
            let progress = min(age / rocket.flight, 1)
            drawTrail(of: rocket, age: age, progress: progress, in: &context, palette: palette, glow: glow)
            guard progress >= 1 else { continue }
            drawBurst(burst, of: rocket, age: CGFloat(age - rocket.flight), in: &context, palette: palette, glow: glow)
        }
    }

    /// A tapered trail behind the rocket (thin and clear at its tail), a ✨ head while it flies.
    private func drawTrail(of rocket: FireworksPlan.Rocket, age: TimeInterval, progress: Double,
                           in context: inout GraphicsContext, palette: Palette, glow: Bool) {
        let ease = 1 - pow(1 - progress, 2.2)
        let alpha = progress < 1 ? 0.9 : max(0, 0.9 - (age - rocket.flight) * 1.6)
        guard alpha > 0 else { return }
        let segments = 24
        for s in 0..<segments {
            let a = max(0, ease - 0.45 + Double(s) / Double(segments) * 0.45)
            let b = max(0, ease - 0.45 + Double(s + 1) / Double(segments) * 0.45)
            var path = Path()
            path.move(to: point(of: rocket, at: a))
            path.addLine(to: point(of: rocket, at: b))
            context.opacity = alpha * Double(s) / Double(segments)
            context.stroke(path, with: palette.trail,
                           style: StrokeStyle(lineWidth: (1 + CGFloat(s) / CGFloat(segments) * 3) * scale,
                                              lineCap: .round))
        }
        if progress < 1 {
            context.opacity = 1
            // The prototype's head glows wider than the rest (shadow 18 px in the trail color).
            let head = point(of: rocket, at: ease)
            context.fill(sparkle(at: head, height: 18 * scale * (glow ? 1.6 : 1)),
                         with: glow ? palette.trail : palette.star)
        }
    }

    private func drawBurst(_ burst: Burst, of rocket: FireworksPlan.Rocket, age: CGFloat,
                           in context: inout GraphicsContext, palette: Palette, glow: Bool) {
        // Full strength for 0.7 s, then gone when the plan ends the burst.
        let fade = max(0, 1 - max(0, age - 0.7) / (FireworksPlan.burstLife - 0.7))
        guard fade > 0 else { return }
        let pair = palette.pairs[rocket.pair % palette.pairs.count]
        let center = rocket.burst
        let grow = 1 - exp(-age * 4.2)
        let fall = 38 * scale * age * age

        // Streaks: clear at the inner end, brightest outside; the inner ends move out after 0.35 s.
        context.opacity = fade
        for streak in burst.streaks {
            let ink = streak.second ? pair.1 : pair.0
            let outer = streak.length * grow
            let inner = outer * (0.08 + 0.42 * max(0, age - 0.35))
            let from = point(around: center, angle: streak.angle, distance: inner, drop: fall * 0.6)
            let to = point(around: center, angle: streak.angle, distance: outer, drop: fall)
            var path = Path()
            path.move(to: from)
            path.addLine(to: to)
            let shading = glow ? ink.glow : .linearGradient(ink.streak, startPoint: from, endPoint: to)
            context.stroke(path, with: shading, lineWidth: streak.width)
        }

        // Flickering dots just outside the streaks.
        for dot in burst.dots {
            let distance = dot.distance * grow
            let flicker = 0.55 + 0.45 * sin(age * 22 + dot.phase)
            let c = point(around: center, angle: dot.angle, distance: distance, drop: fall * 1.1)
            context.opacity = fade * flicker
            context.fill(Path(ellipseIn: CGRect(x: c.x - dot.radius, y: c.y - dot.radius,
                                                width: 2 * dot.radius, height: 2 * dot.radius)),
                         with: (dot.second ? pair.1 : pair.0).color)
        }

        // The 16-point star flash in the center, fading in 0.6 s (its glow is wider: 30 px).
        if age < 0.6 {
            context.opacity = 1 - age / 0.6
            let radius = (rocket.isFinale ? 60 : 38) * scale * (0.6 + age) * (glow ? 1.5 : 1)
            context.fill(flash(at: center, radius: radius), with: palette.star)
        }

        // Twinkling ✨ around the burst.
        for twinkle in burst.twinkles {
            let t = age - twinkle.delay
            guard t >= 0 else { continue }
            let strength = max(0, sin(t * 9 + twinkle.phase)) * max(0, 1 - t / 1.3)
            guard strength > 0 else { continue }
            let c = point(around: center, angle: twinkle.angle, distance: twinkle.distance, drop: fall)
            context.opacity = strength * fade
            context.fill(sparkle(at: c, height: twinkle.height * (0.6 + strength * 0.6)),
                         with: palette.glows ? palette.star : pair.0.color)
        }
    }

    /// The point at `t` (0…1) on the rocket's curved path (the prototype's `bez`).
    private func point(of rocket: FireworksPlan.Rocket, at t: Double) -> CGPoint {
        let control = CGPoint(x: (rocket.start.x + rocket.burst.x) / 2 + rocket.bend,
                              y: (rocket.start.y + rocket.burst.y) / 2)
        let u = 1 - t
        return CGPoint(x: u * u * rocket.start.x + 2 * u * t * control.x + t * t * rocket.burst.x,
                       y: u * u * rocket.start.y + 2 * u * t * control.y + t * t * rocket.burst.y)
    }

    private func point(around center: CGPoint, angle: CGFloat, distance: CGFloat, drop: CGFloat) -> CGPoint {
        CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance + drop)
    }

    /// A ✨ of the given star height, centered on `center`.
    private func sparkle(at center: CGPoint, height: CGFloat) -> Path {
        // `SparkleShape` draws a 38-high star in a 40 × 40 box.
        let side = height * 40 / 38
        return SparkleShape().path(in: CGRect(x: center.x - side / 2, y: center.y - side / 2,
                                              width: side, height: side))
    }

    private func flash(at center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        for i in 0..<16 {
            let angle = CGFloat(i) / 16 * 2 * .pi
            let r = i % 2 == 1 ? radius * 0.28 : radius
            let p = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}
