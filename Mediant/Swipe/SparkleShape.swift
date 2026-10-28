import SwiftUI

/// ✨-like sparkle: four long, thin, concave points, taller than wide. Optionally a 3-star cluster.
struct SparkleShape: Shape {
    var cluster = false

    func path(in rect: CGRect) -> Path {
        // Drawn in a 40×40 box, then scaled to `rect`.
        var path = Path()
        if cluster {
            addStar(to: &path, center: CGPoint(x: 24, y: 23), height: 32)
            addStar(to: &path, center: CGPoint(x: 9, y: 9), height: 15)
            addStar(to: &path, center: CGPoint(x: 8, y: 32), height: 9)
        } else {
            addStar(to: &path, center: CGPoint(x: 20, y: 20), height: 38)
        }
        let scale = CGAffineTransform(scaleX: rect.width / 40, y: rect.height / 40)
        return path.applying(scale.concatenating(CGAffineTransform(translationX: rect.minX, y: rect.minY)))
    }

    private func addStar(to path: inout Path, center c: CGPoint, height h: CGFloat) {
        let w = h * 0.58, k = h * 0.035
        path.move(to: CGPoint(x: c.x, y: c.y - h / 2))
        path.addQuadCurve(to: CGPoint(x: c.x + w / 2, y: c.y), control: CGPoint(x: c.x + k, y: c.y - k))
        path.addQuadCurve(to: CGPoint(x: c.x, y: c.y + h / 2), control: CGPoint(x: c.x + k, y: c.y + k))
        path.addQuadCurve(to: CGPoint(x: c.x - w / 2, y: c.y), control: CGPoint(x: c.x - k, y: c.y + k))
        path.addQuadCurve(to: CGPoint(x: c.x, y: c.y - h / 2), control: CGPoint(x: c.x - k, y: c.y - k))
        path.closeSubpath()
    }
}
