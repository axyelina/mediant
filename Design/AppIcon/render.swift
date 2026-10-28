// Renders the icon SVGs to 1024x1024 opaque PNGs in the AppIcon set.
// Run from the repo root: swift Design/AppIcon/render.swift
import AppKit

let src = "Design/AppIcon"
let dst = "Mediant/Assets.xcassets/AppIcon.appiconset"
let size = 1024

for name in ["light", "dark", "tinted"] {
    guard let svg = NSImage(contentsOfFile: "\(src)/\(name).svg") else {
        fatalError("cannot read \(name).svg")
    }
    var rect = NSRect(x: 0, y: 0, width: size, height: size)
    guard let image = svg.cgImage(forProposedRect: &rect, context: nil, hints: nil),
          let ctx = CGContext(
              data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
              space: CGColorSpace(name: CGColorSpace.sRGB)!,
              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
    else { fatalError("cannot render \(name).svg") }
    ctx.draw(image, in: rect)
    try! NSBitmapImageRep(cgImage: ctx.makeImage()!)
        .representation(using: .png, properties: [:])!
        .write(to: URL(fileURLWithPath: "\(dst)/AppIcon-\(name).png"))
    print("wrote AppIcon-\(name).png")
}
