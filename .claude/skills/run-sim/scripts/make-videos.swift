// Draws short sample videos (a gradient with a moving ball) in portrait, landscape and square as MP4s.
// Usage: swift make-videos.swift <output-dir>
import AVFoundation
import CoreGraphics
import Foundation

let out = URL(fileURLWithPath: CommandLine.arguments[1])
// Portrait, landscape, square, screen-tall.
let shapes: [(Int, Int)] = [(720, 1280), (1280, 720), (720, 720), (590, 1278)]
let fps: Int32 = 30
let seconds = 4
try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

for (n, (w, h)) in shapes.enumerated() {
    let url = out.appendingPathComponent("video-\(n).mp4")
    try? FileManager.default.removeItem(at: url)
    let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
        AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: w, AVVideoHeightKey: h,
    ])
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
        kCVPixelBufferWidthKey as String: w, kCVPixelBufferHeightKey as String: h,
    ])
    writer.add(input)
    writer.startWriting()
    writer.startSession(atSourceTime: .zero)

    let hue = Double(n) / Double(shapes.count)
    for frame in 0..<(Int(fps) * seconds) {
        while !input.isReadyForMoreMediaData { usleep(1_000) }
        var buffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &buffer)
        CVPixelBufferLockBaseAddress(buffer!, [])
        let ctx = CGContext(data: CVPixelBufferGetBaseAddress(buffer!), width: w, height: h, bitsPerComponent: 8,
                            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer!), space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
        let t = Double(frame) / Double(Int(fps) * seconds)
        let colors = [CGColor(red: 0.2 + 0.6 * hue, green: 0.3, blue: 0.8 - 0.5 * hue, alpha: 1),
                      CGColor(red: 0.1, green: 0.1 + 0.4 * t, blue: 0.2, alpha: 1)] as CFArray
        ctx.drawLinearGradient(CGGradient(colorsSpace: nil, colors: colors, locations: nil)!,
                               start: .zero, end: CGPoint(x: w, y: h), options: [])
        // A white frame shows where the video's edges are, so cropping is easy to spot.
        ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.9))
        ctx.setLineWidth(12)
        ctx.stroke(CGRect(x: 6, y: 6, width: w - 12, height: h - 12))
        let r = Double(min(w, h)) / 6
        let x = r + (Double(w) - 2 * r) * (0.5 + 0.5 * sin(2 * .pi * t))
        let y = r + (Double(h) - 2 * r) * (0.5 + 0.5 * cos(2 * .pi * t))
        ctx.setFillColor(CGColor(red: 1, green: 0.85, blue: 0.3, alpha: 1))
        ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r))
        CVPixelBufferUnlockBaseAddress(buffer!, [])
        adaptor.append(buffer!, withPresentationTime: CMTime(value: CMTimeValue(frame), timescale: fps))
    }
    input.markAsFinished()
    let done = DispatchSemaphore(value: 0)
    writer.finishWriting { done.signal() }
    done.wait()
    if writer.status != .completed { fatalError("\(url.lastPathComponent): \(String(describing: writer.error))") }
}
print("Wrote \(shapes.count) videos to \(out.path)")
