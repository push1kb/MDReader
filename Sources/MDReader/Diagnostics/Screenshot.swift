import AppKit
import MDReaderCore
import SwiftUI

/// `MDReader --screenshot` renders the panel reading the Markdown on the clipboard (the README uses
/// `Samples/screenshot.md`) into a framed
/// PNG for the README, prints its path and quits. The live Liquid Glass blur can't be drawn
/// offscreen, so the panel sits on a solid background.
@MainActor
enum Screenshot {
    static var isRequested: Bool { CommandLine.arguments.contains("--screenshot") }

    private static let panelSize = CGSize(width: 420, height: 520)
    private static let margin: CGFloat = 64

    static func render() {
        let markdown = NSPasteboard.general.string(forType: .string) ?? ""
        let controller = PlayerController.preview(markdown: markdown, currentChunk: 3)
        let panel = ReaderView(controller: controller, presentation: .window, tab: .speakingNow)
            .frame(width: panelSize.width, height: panelSize.height)
            .background(Color(nsColor: .windowBackgroundColor))

        let hosting = NSHostingView(rootView: panel)
        let window = NSWindow(contentRect: CGRect(origin: CGPoint(x: -10_000, y: 0), size: panelSize),
                              styleMask: .borderless, backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: .aqua)
        window.contentView = hosting
        window.orderFrontRegardless()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let capture = bitmap(size: panelSize)
            hosting.cacheDisplay(in: hosting.bounds, to: capture)
            let url = URL.temporaryDirectory.appending(path: "MDReader-screenshot.png")
            try? framed(capture).write(to: url)
            print(url.path)
            exit(0)
        }
    }

    /// A Retina (2×) bitmap measuring `size` in points.
    private static func bitmap(size: CGSize) -> NSBitmapImageRep {
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width * 2), pixelsHigh: Int(size.height * 2),
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                   colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        rep.size = size
        return rep
    }

    /// The panel with rounded corners and a shadow, on a soft gradient.
    private static func framed(_ capture: NSBitmapImageRep) -> Data {
        let size = CGSize(width: panelSize.width + margin * 2, height: panelSize.height + margin * 2)
        let output = bitmap(size: size)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: output)
        let bounds = CGRect(origin: .zero, size: size)
        let context = NSGraphicsContext.current!.cgContext
        let backdrop = NSGradient(colors: [NSColor(red: 0.30, green: 0.50, blue: 1.00, alpha: 1),
                                           NSColor(red: 0.47, green: 0.26, blue: 0.90, alpha: 1)])!
        backdrop.draw(in: bounds, angle: -45)

        let frame = CGRect(origin: CGPoint(x: margin, y: margin), size: panelSize)
        let shape = NSBezierPath(roundedRect: frame, xRadius: 16, yRadius: 16)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -14), blur: 40,
                          color: NSColor.black.withAlphaComponent(0.35).cgColor)
        NSColor.windowBackgroundColor.setFill()
        shape.fill()
        context.restoreGState()

        shape.addClip()
        capture.draw(in: frame)
        NSGraphicsContext.restoreGraphicsState()
        return output.representation(using: .png, properties: [:])!
    }
}
