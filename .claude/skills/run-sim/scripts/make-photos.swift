// Draws sample photos (gradients + shapes) in mixed aspect ratios as JPEGs.
// Usage: swift make-photos.swift <output-dir> <count>
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let out = URL(fileURLWithPath: CommandLine.arguments[1])
let count = Int(CommandLine.arguments[2]) ?? 40
// Portrait, landscape, square, panorama, screenshot-tall.
let shapes: [(Int, Int)] = [(1200, 1600), (1600, 1200), (1400, 1400), (2400, 1000), (1179, 2556), (1080, 1920), (1920, 1080)]
try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
var rng = SystemRandomNumberGenerator()

func color(_ hue: Double, _ sat: Double, _ bri: Double) -> CGColor {
    // HSB → RGB
    let h = hue * 6, i = Int(h) % 6, f = h - floor(h)
    let p = bri * (1 - sat), q = bri * (1 - f * sat), t = bri * (1 - (1 - f) * sat)
    let (r, g, b): (Double, Double, Double) = [(bri, t, p), (q, bri, p), (p, bri, t), (p, q, bri), (t, p, bri), (bri, p, q)][i]
    return CGColor(red: r, green: g, blue: b, alpha: 1)
}

for n in 0..<count {
    let (w, h) = shapes[n % shapes.count]
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    let hue = Double.random(in: 0..<1, using: &rng)
    let gradient = CGGradient(colorsSpace: nil, colors: [color(hue, 0.6, 0.9), color((hue + 0.15).truncatingRemainder(dividingBy: 1), 0.8, 0.35)] as CFArray, locations: nil)!
    ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: w, y: h), options: [])
    for _ in 0..<Int.random(in: 8...30, using: &rng) {
        ctx.setFillColor(color(Double.random(in: 0..<1, using: &rng), 0.5, 1).copy(alpha: 0.35)!)
        let r = Double.random(in: 30...Double(min(w, h)) / 3, using: &rng)
        ctx.fillEllipse(in: CGRect(x: .random(in: 0...Double(w), using: &rng), y: .random(in: 0...Double(h), using: &rng), width: r, height: r))
    }
    // Noise lines make file sizes differ like real photos.
    for _ in 0..<Int.random(in: 0...4000, using: &rng) {
        ctx.setStrokeColor(color(Double.random(in: 0..<1, using: &rng), 0.3, 1).copy(alpha: 0.25)!)
        ctx.move(to: CGPoint(x: .random(in: 0...Double(w), using: &rng), y: .random(in: 0...Double(h), using: &rng)))
        ctx.addLine(to: CGPoint(x: .random(in: 0...Double(w), using: &rng), y: .random(in: 0...Double(h), using: &rng)))
        ctx.strokePath()
    }
    let url = out.appendingPathComponent(String(format: "mediant-sample-%02d.jpg", n))
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
    CGImageDestinationFinalize(dest)
}
print("made \(count) photos in \(out.path)")
