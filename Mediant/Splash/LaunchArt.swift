import CoreGraphics

/// The launch picture in screen points: the app icon stretched to a tall screen.
///
/// The art is drawn in icon units (the icon is 100×100, center 50,50). The launch image
/// (`Design/AppIcon/launch-*.svg`) extends it to 100×220 and is shown aspect-fill, so on every
/// iPhone it is scaled by the screen width and centered. The splash draws the same art in code.
struct LaunchArt {
    struct Star: Equatable {
        var center: CGPoint
        var size: CGSize
    }

    let screen: CGSize

    /// Icon stars: center and size in icon units. Big, top-right small, bottom-left small.
    static let iconStars: [(center: CGPoint, size: CGSize)] = [
        (CGPoint(x: 50, y: 50), CGSize(width: 62, height: 80)),
        (CGPoint(x: 76, y: 24), CGSize(width: 16, height: 22)),
        (CGPoint(x: 24, y: 78), CGSize(width: 11, height: 15)),
    ]
    /// Icon star curves: control points 7 units off center in a 100-unit star.
    static let iconPinch: CGFloat = 0.07

    var scale: CGFloat { screen.width / 100 }

    func point(_ p: CGPoint) -> CGPoint {
        CGPoint(x: (p.x - 50) * scale + screen.width / 2, y: (p.y - 50) * scale + screen.height / 2)
    }

    /// Same order as `SparkleShape.clusterStars`, so star i flies to cluster star i.
    var stars: [Star] {
        Self.iconStars.map {
            Star(center: point($0.center), size: CGSize(width: $0.size.width * scale, height: $0.size.height * scale))
        }
    }

    /// The delete (left) side of the diagonal: top and bottom of the line, then the left edge.
    /// In the icon the line runs from (62, 0) to (38, 100); here it reaches past both screen ends.
    var deleteSide: [CGPoint] {
        let reach = (screen.height / 2) / scale + 10
        return [
            point(CGPoint(x: 50 + 0.24 * reach, y: 50 - reach)),
            point(CGPoint(x: 50 - 0.24 * reach, y: 50 + reach)),
            CGPoint(x: -1, y: point(CGPoint(x: 0, y: 50 + reach)).y),
            CGPoint(x: -1, y: point(CGPoint(x: 0, y: 50 - reach)).y),
        ]
    }

    /// Where the stars of a `SparkleShape(cluster: true)` drawn in `rect` are.
    static func clusterStars(in rect: CGRect) -> [Star] {
        let sx = rect.width / 40, sy = rect.height / 40
        return SparkleShape.clusterStars.map {
            Star(center: CGPoint(x: rect.minX + $0.center.x * sx, y: rect.minY + $0.center.y * sy),
                 size: CGSize(width: $0.height * SparkleShape.widthRatio * sx, height: $0.height * sy))
        }
    }
}
