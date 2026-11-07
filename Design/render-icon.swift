// Renders the MDReader app icon. Usage: swift Design/render-icon.swift <output.png> [size]
import AppKit

let output = CommandLine.arguments[1]
let size = CommandLine.arguments.count > 2 ? CGFloat(Double(CommandLine.arguments[2])!) : 1024
let scale = size / 1024

let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.scaleBy(x: scale, y: scale)

    // macOS icon grid: an 824 pt rounded square centred on a 1024 canvas.
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    let tilePath = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: NSColor.black.withAlphaComponent(0.35).cgColor)
    ctx.addPath(tilePath)
    ctx.setFillColor(NSColor.black.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(tilePath)
    ctx.clip()
    let background = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
        NSColor(red: 0.30, green: 0.50, blue: 1.00, alpha: 1).cgColor,
        NSColor(red: 0.47, green: 0.26, blue: 0.90, alpha: 1).cgColor,
    ] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(background, start: CGPoint(x: 150, y: 924), end: CGPoint(x: 874, y: 100), options: [])
    // Soft highlight across the top.
    let sheen = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
        NSColor.white.withAlphaComponent(0.22).cgColor, NSColor.white.withAlphaComponent(0).cgColor,
    ] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(sheen, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 560), options: [])
    ctx.restoreGState()

    // The page.
    let page = CGRect(x: 216, y: 250, width: 340, height: 524)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 22, color: NSColor.black.withAlphaComponent(0.25).cgColor)
    ctx.addPath(CGPath(roundedRect: page, cornerWidth: 44, cornerHeight: 44, transform: nil))
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // A Markdown heading mark…
    let accent = NSColor(red: 0.38, green: 0.36, blue: 0.95, alpha: 1)
    let hash = NSAttributedString(string: "#", attributes: [
        .font: NSFont.systemFont(ofSize: 150, weight: .heavy),
        .foregroundColor: accent,
    ])
    hash.draw(at: CGPoint(x: page.minX + 40, y: page.maxY - 190))

    // …and lines of text.
    ctx.setFillColor(NSColor(red: 0.80, green: 0.80, blue: 0.90, alpha: 1).cgColor)
    for (index, width) in [240.0, 260, 200, 250, 150].enumerated() {
        let bar = CGRect(x: page.minX + 44, y: page.maxY - 250 - CGFloat(index) * 52, width: width, height: 26)
        ctx.addPath(CGPath(roundedRect: bar, cornerWidth: 13, cornerHeight: 13, transform: nil))
        ctx.fillPath()
    }

    // Sound waves coming off the page.
    let center = CGPoint(x: page.maxX + 6, y: page.midY)
    ctx.setLineCap(.round)
    ctx.setLineWidth(34)
    for (index, radius) in [92.0, 158, 224].enumerated() {
        ctx.setStrokeColor(NSColor.white.withAlphaComponent(1 - CGFloat(index) * 0.2).cgColor)
        ctx.addArc(center: center, radius: radius, startAngle: -.pi / 4, endAngle: .pi / 4, clockwise: false)
        ctx.strokePath()
    }
    return true
}

let tiff = image.tiffRepresentation!
let png = NSBitmapImageRep(data: tiff)!.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: output))
