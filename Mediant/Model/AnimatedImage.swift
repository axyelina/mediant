import Foundation
import ImageIO

/// Facts about image file data that decide whether it plays as an animation.
enum AnimatedImage {
    /// The number of frames in the data: more than 1 is an animation, 1 a still picture, 0 data
    /// that ImageIO cannot read.
    static func frameCount(of data: Data) -> Int {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return 0 }
        return CGImageSourceGetCount(source)
    }
}
