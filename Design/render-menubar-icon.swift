// Renders MDReader's menu bar icon as template PDFs (black on transparent; macOS tints them).
// Usage: swift Design/render-menubar-icon.swift <idle.pdf> <playing.pdf> [preview.png]
import AppKit

let size = CGSize(width: 18, height: 18)
let lineWidth: CGFloat = 1.5
let page = CGRect(x: 1.75, y: 1.75, width: 8.5, height: 14.5)
/// A Markdown heading mark at the top of the page, like the app icon's.
let hash = CGRect(x: 3.85, y: 10.1, width: 4.3, height: 4.4)
let textLines: [(y: CGFloat, width: CGFloat)] = [(6.75, 5), (4.0, 3.75)]

/// The heading mark and lines of text as filled outlines, so they can be drawn on the outlined page
/// or cut out of the solid one. (PDF has no "clear" blend mode, so cut-outs must be real geometry.)
func details() -> CGPath {
    let lines = CGMutablePath()
    for line in textLines {
        lines.move(to: CGPoint(x: page.minX + 2.25, y: line.y))
        lines.addLine(to: CGPoint(x: page.minX + 2.25 + line.width - 1, y: line.y))
    }

    let mark = CGMutablePath()
    let inset: CGFloat = 1.25, slant: CGFloat = 0.45
    for x in [hash.minX + inset, hash.maxX - inset] {
        mark.move(to: CGPoint(x: x - slant, y: hash.minY))
        mark.addLine(to: CGPoint(x: x + slant, y: hash.maxY))
    }
    for y in [hash.minY + inset, hash.maxY - inset] {
        mark.move(to: CGPoint(x: hash.minX, y: y))
        mark.addLine(to: CGPoint(x: hash.maxX, y: y))
    }

    return lines.copy(strokingWithWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 10)
        .union(mark.copy(strokingWithWidth: 1.15, lineCap: .round, lineJoin: .round, miterLimit: 10))
}

func draw(_ context: CGContext, playing: Bool) {
    context.setFillColor(.black)
    context.setStrokeColor(.black)
    context.setLineWidth(lineWidth)
    context.setLineCap(.round)

    let pagePath = CGPath(roundedRect: page, cornerWidth: 2, cornerHeight: 2, transform: nil)
    if playing {
        context.addPath(pagePath.subtracting(details()))
        context.fillPath()
    } else {
        context.addPath(pagePath)
        context.strokePath()
        context.addPath(details())
        context.fillPath()
    }

    // Two sound waves off the page's right edge.
    let center = CGPoint(x: page.maxX + 0.25, y: page.midY)
    for radius in [3.5, 6.25] {
        context.addArc(center: center, radius: radius, startAngle: -.pi / 4.2, endAngle: .pi / 4.2, clockwise: false)
        context.strokePath()
    }
}

func writePDF(to path: String, playing: Bool) {
    var box = CGRect(origin: .zero, size: size)
    let context = CGContext(URL(fileURLWithPath: path) as CFURL, mediaBox: &box, nil)!
    context.beginPDFPage(nil)
    draw(context, playing: playing)
    context.endPDFPage()
    context.closePDF()
}

let arguments = CommandLine.arguments
writePDF(to: arguments[1], playing: false)
writePDF(to: arguments[2], playing: true)

// Optional enlarged preview of both generated PDFs on a light and a dark menu bar.
if arguments.count > 3 {
    let scale: CGFloat = 8
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width * scale * 4), pixelsHigh: Int(size.height * scale * 2),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let context = NSGraphicsContext.current!.cgContext
    for (row, background) in [CGColor(gray: 0.93, alpha: 1), CGColor(gray: 0.16, alpha: 1)].enumerated() {
        context.setFillColor(background)
        context.fill(CGRect(x: 0, y: CGFloat(1 - row) * size.height * scale, width: size.width * scale * 4, height: size.height * scale))
        for (column, playing) in [false, true].enumerated() {
            context.saveGState()
            context.translateBy(x: (CGFloat(column) * 2 + 0.5) * size.width * scale, y: CGFloat(1 - row) * size.height * scale)
            context.scaleBy(x: scale, y: scale)
            context.beginTransparencyLayer(auxiliaryInfo: nil)
            let pdf = CGPDFDocument(URL(fileURLWithPath: arguments[playing ? 2 : 1]) as CFURL)!
            context.drawPDFPage(pdf.page(at: 1)!)
            context.setBlendMode(.sourceIn)
            context.setFillColor(row == 0 ? CGColor(gray: 0, alpha: 0.85) : CGColor(gray: 1, alpha: 0.9))
            context.fill(CGRect(origin: .zero, size: size))
            context.endTransparencyLayer()
            context.restoreGState()
        }
    }
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: arguments[3]))
}
