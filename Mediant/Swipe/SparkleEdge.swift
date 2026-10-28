import SwiftUI

/// Twinkling ✨-style sparkles along one screen edge. `progress` (0…1) fades them in with the
/// finger; when it drops to 0 (a swipe ends) they keep twinkling and fade out slowly.
struct SparkleEdge: View {
    enum Side { case leading, trailing }

    let side: Side
    let color: Color
    let progress: Double

    @State private var sparkles = (0..<30).map { _ in Sparkle.random() }
    @State private var shown = 0.0
    @State private var isRunning = false

    var body: some View {
        Group {
            if isRunning { sparkleCanvas.opacity(shown) }
        }
        .allowsHitTesting(false)
        .onChange(of: progress, initial: true) { _, new in
            if new > 0 {
                isRunning = true
                shown = new
            } else {
                withAnimation(.easeOut(duration: 0.7)) {
                    shown = 0
                } completion: {
                    if progress == 0 { isRunning = false }
                }
            }
        }
    }

    private var sparkleCanvas: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                context.addFilter(.shadow(color: color.opacity(0.9), radius: 2))
                context.addFilter(.shadow(color: color.opacity(0.9), radius: 7))
                for sparkle in sparkles {
                    let t = (sin(2 * .pi * (time / sparkle.period + sparkle.phase)) + 1) / 2
                    let scale = 0.4 + 0.7 * t
                    let side = sparkle.size * scale
                    let x = side == 0 ? 0 : sparkle.inset
                    let centerX = self.side == .leading ? x : size.width - x
                    let center = CGPoint(x: centerX, y: sparkle.y * size.height)
                    var star = context
                    star.opacity = 0.3 + 0.7 * t
                    star.translateBy(x: center.x, y: center.y)
                    star.rotate(by: .degrees(-8 + 14 * t))
                    let rect = CGRect(x: -side / 2, y: -side / 2, width: side, height: side)
                    star.fill(SparkleShape(cluster: sparkle.cluster).path(in: rect), with: .color(color))
                }
            }
        }
    }

    private struct Sparkle {
        let inset: CGFloat
        let y: CGFloat
        let size: CGFloat
        let period: Double
        let phase: Double
        let cluster: Bool

        /// Denser near the screen edge.
        static func random() -> Sparkle {
            Sparkle(inset: pow(.random(in: 0...1), 1.8) * 100,
                    y: .random(in: 0.04...0.92),
                    size: .random(in: 12...32),
                    period: .random(in: 0.9...2.1),
                    phase: .random(in: 0...1),
                    cluster: Double.random(in: 0...1) < 0.35)
        }
    }
}
