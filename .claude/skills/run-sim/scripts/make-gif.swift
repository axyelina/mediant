// Writes sample-ball.gif into the given folder: a pink ball moving across a dark frame inside a
// white border, 12 frames of 0.08 s, looping forever. Drawn in code; no download.
// Usage: swift make-gif.swift <outdir>
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let outDir = URL(fileURLWithPath: CommandLine.arguments[1])
let url = outDir.appendingPathComponent("sample-ball.gif")
let size = 360, frames = 12
let loop = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary
let delay = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 0.08]] as CFDictionary

guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, frames, nil),
      let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                              space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
else { fatalError("cannot create the GIF") }
CGImageDestinationSetProperties(destination, loop)

for frame in 0..<frames {
    let s = CGFloat(size)
    context.setFillColor(red: 0.08, green: 0.08, blue: 0.1, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: s, height: s))
    context.setStrokeColor(red: 1, green: 1, blue: 1, alpha: 1)
    context.setLineWidth(8)
    context.stroke(CGRect(x: 4, y: 4, width: s - 8, height: s - 8))
    let x = 40 + (s - 160) * CGFloat(frame) / CGFloat(frames - 1)
    context.setFillColor(red: 1, green: 0.36, blue: 0.58, alpha: 1)
    context.fillEllipse(in: CGRect(x: x, y: s / 2 - 40, width: 80, height: 80))
    CGImageDestinationAddImage(destination, context.makeImage()!, delay)
}
guard CGImageDestinationFinalize(destination) else { fatalError("cannot write the GIF") }
print(url.path)
