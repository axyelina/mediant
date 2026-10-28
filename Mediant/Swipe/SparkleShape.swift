import SwiftUI

/// ✨-like sparkle: four long, thin, concave points, taller than wide. Optionally a 3-star cluster.
struct SparkleShape: Shape {
    var cluster = false

    /// Star width as a fraction of its height.
    static let widthRatio: CGFloat = 0.58
    /// How far the curves bend toward the center, as a fraction of the star height.
    static let pinch: CGFloat = 0.035
    /// The cluster in a 40×40 box: big star first, then the top-left and bottom-left small ones.
    static let clusterStars: [(center: CGPoint, height: CGFloat)] = [
        (CGPoint(x: 24, y: 23), 32),
        (CGPoint(x: 9, y: 9), 15),
        (CGPoint(x: 8, y: 32), 9),
    ]

    func path(in rect: CGRect) -> Path {
        // Drawn in a 40×40 box, then scaled to `rect`.
        var path = Path()
        for star in cluster ? Self.clusterStars : [(CGPoint(x: 20, y: 20), 38)] {
            let h = star.height, w = h * Self.widthRatio
            let box = CGRect(x: star.center.x - w / 2, y: star.center.y - h / 2, width: w, height: h)
            path.addPath(StarShape.star(in: box, pinchX: Self.pinch / Self.widthRatio, pinchY: Self.pinch))
        }
        let scale = CGAffineTransform(scaleX: rect.width / 40, y: rect.height / 40)
        return path.applying(scale.concatenating(CGAffineTransform(translationX: rect.minX, y: rect.minY)))
    }
}

/// One four-point star filling its frame. `pinchX`/`pinchY` place the curve controls off the
/// center as a fraction of the width/height; both animate, so a star can morph between styles.
struct StarShape: Shape {
    var pinchX: CGFloat
    var pinchY: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(pinchX, pinchY) }
        set { (pinchX, pinchY) = (newValue.first, newValue.second) }
    }

    func path(in rect: CGRect) -> Path {
        Self.star(in: rect, pinchX: pinchX, pinchY: pinchY)
    }

    static func star(in rect: CGRect, pinchX: CGFloat, pinchY: CGFloat) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let kx = rect.width * pinchX, ky = rect.height * pinchY
        var path = Path()
        path.move(to: CGPoint(x: c.x, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: c.y), control: CGPoint(x: c.x + kx, y: c.y - ky))
        path.addQuadCurve(to: CGPoint(x: c.x, y: rect.maxY), control: CGPoint(x: c.x + kx, y: c.y + ky))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: c.y), control: CGPoint(x: c.x - kx, y: c.y + ky))
        path.addQuadCurve(to: CGPoint(x: c.x, y: rect.minY), control: CGPoint(x: c.x - kx, y: c.y - ky))
        path.closeSubpath()
        return path
    }
}
