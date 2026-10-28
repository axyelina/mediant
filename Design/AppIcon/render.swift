// Renders the icon and launch SVGs to opaque PNGs in the asset catalog.
// Run from the repo root: swift Design/AppIcon/render.swift
import AppKit

let src = "Design/AppIcon"
let icons = "Mediant/Assets.xcassets/AppIcon.appiconset"
let launch = "Mediant/Assets.xcassets/LaunchArt.imageset"
let jobs: [(svg: String, png: String, width: Int, height: Int)] = [
    ("light", "\(icons)/AppIcon-light.png", 1024, 1024),
    ("dark", "\(icons)/AppIcon-dark.png", 1024, 1024),
    ("tinted", "\(icons)/AppIcon-tinted.png", 1024, 1024),
    ("launch-light", "\(launch)/LaunchArt-light.png", 1320, 2904),
    ("launch-dark", "\(launch)/LaunchArt-dark.png", 1320, 2904),
]

for job in jobs {
    guard let svg = NSImage(contentsOfFile: "\(src)/\(job.svg).svg") else {
        fatalError("cannot read \(job.svg).svg")
    }
    var rect = NSRect(x: 0, y: 0, width: job.width, height: job.height)
    guard let image = svg.cgImage(forProposedRect: &rect, context: nil, hints: nil),
          let ctx = CGContext(
              data: nil, width: job.width, height: job.height, bitsPerComponent: 8, bytesPerRow: 0,
              space: CGColorSpace(name: CGColorSpace.sRGB)!,
              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
    else { fatalError("cannot render \(job.svg).svg") }
    ctx.draw(image, in: rect)
    try! NSBitmapImageRep(cgImage: ctx.makeImage()!)
        .representation(using: .png, properties: [:])!
        .write(to: URL(fileURLWithPath: job.png))
    print("wrote \(job.png)")
}
