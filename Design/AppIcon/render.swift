// Renders the icon and launch SVGs to opaque PNGs in the asset catalog, and the tip images
// (Design/Tips) for App Store Connect. Run from the repo root: swift Design/AppIcon/render.swift
import AppKit

let src = "Design"
let icons = "Mediant/Assets.xcassets/AppIcon.appiconset"
let launch = "Mediant/Assets.xcassets/LaunchArt.imageset"
let tips = "fastlane/tips"
let jobs: [(svg: String, png: String, width: Int, height: Int)] = [
    ("AppIcon/light", "\(icons)/AppIcon-light.png", 1024, 1024),
    ("AppIcon/dark", "\(icons)/AppIcon-dark.png", 1024, 1024),
    ("AppIcon/tinted", "\(icons)/AppIcon-tinted.png", 1024, 1024),
    ("AppIcon/launch-light", "\(launch)/LaunchArt-light.png", 1320, 2904),
    ("AppIcon/launch-dark", "\(launch)/LaunchArt-dark.png", 1320, 2904),
    ("Tips/tip-small", "\(tips)/tip-small.png", 1024, 1024),
    ("Tips/tip-medium", "\(tips)/tip-medium.png", 1024, 1024),
    ("Tips/tip-large", "\(tips)/tip-large.png", 1024, 1024),
    ("Tips/tip-huge", "\(tips)/tip-huge.png", 1024, 1024),
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
