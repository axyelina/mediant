import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import Mediant

struct AnimatedImageTests {
    /// A tiny image file made in memory: `frames` one-pixel frames of the given type.
    func imageData(type: UTType, frames: Int) -> Data {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, type.identifier as CFString, frames, nil)!
        let context = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        for shade in 0..<frames {
            context.setFillColor(gray: CGFloat(shade) / CGFloat(max(frames, 1)), alpha: 1)
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            CGImageDestinationAddImage(destination, context.makeImage()!, nil)
        }
        CGImageDestinationFinalize(destination)
        return data as Data
    }

    @Test func countsTheFramesOfAGIF() {
        #expect(AnimatedImage.frameCount(of: imageData(type: .gif, frames: 3)) == 3)
    }

    @Test func aStillPictureHasOneFrame() {
        #expect(AnimatedImage.frameCount(of: imageData(type: .png, frames: 1)) == 1)
    }

    @Test func unreadableDataHasNoFrames() {
        #expect(AnimatedImage.frameCount(of: Data("nope".utf8)) == 0)
    }
}
