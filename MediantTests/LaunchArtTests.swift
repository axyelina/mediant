import CoreGraphics
import Testing
@testable import Mediant

struct LaunchArtTests {
    let art = LaunchArt(screen: CGSize(width: 393, height: 852))

    @Test func bigStarIsCenteredAndScaledByWidth() {
        let star = art.stars[0]
        #expect(star.center == CGPoint(x: 196.5, y: 426))
        #expect(abs(star.size.width - 393 * 0.62) < 0.001)
        #expect(abs(star.size.height - 393 * 0.80) < 0.001)
    }

    @Test func smallStarsKeepTheirIconOffsets() {
        // Icon: (76, 24) and (24, 78) in a 100-unit icon centered at (50, 50).
        #expect(abs(art.stars[1].center.x - (196.5 + 26 * 3.93)) < 0.001)
        #expect(abs(art.stars[1].center.y - (426 - 26 * 3.93)) < 0.001)
        #expect(abs(art.stars[2].center.x - (196.5 - 26 * 3.93)) < 0.001)
        #expect(abs(art.stars[2].center.y - (426 + 28 * 3.93)) < 0.001)
    }

    @Test func diagonalCrossesTheScreenCenterAtTheIconAngle() {
        let side = art.deleteSide
        let top = side[0], bottom = side[1]
        let t = (426 - top.y) / (bottom.y - top.y)
        #expect(abs(top.x + (bottom.x - top.x) * t - 196.5) < 0.001)
        // Icon line: 24 units left for every 100 units down.
        #expect(abs((top.x - bottom.x) / (bottom.y - top.y) - 0.24) < 0.001)
        #expect(top.y <= 0 && bottom.y >= 852)
    }

    @Test func clusterStarsMatchSparkleShapeInItsFrame() {
        let stars = LaunchArt.clusterStars(in: CGRect(x: 10, y: 20, width: 40, height: 40))
        #expect(stars.count == 3)
        #expect(stars[0].center == CGPoint(x: 34, y: 43))
        #expect(abs(stars[0].size.height - 32) < 0.001)
        #expect(abs(stars[0].size.width - 32 * SparkleShape.widthRatio) < 0.001)
        #expect(stars[1].center == CGPoint(x: 19, y: 29))
        #expect(stars[2].center == CGPoint(x: 18, y: 52))
    }
}
