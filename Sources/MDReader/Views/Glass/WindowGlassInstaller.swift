import AppKit
import SwiftUI

/// Gives the hosting window a Liquid Glass background.
///
/// SwiftUI has no API for a MenuBarExtra panel's background (`containerBackground(_:for: .window)`
/// doesn't reach it) and paints two opaque layers behind the content. This hides those layers and
/// puts an `NSGlassEffectView` — the behind-window glass system panels use — underneath instead.
/// It relies on SwiftUI's private view layout, so a future macOS may need it revisited.
@available(macOS 26.0, *)
struct WindowGlassInstaller: NSViewRepresentable {
    func makeNSView(context: Context) -> HookView { HookView() }
    func updateNSView(_ view: HookView, context: Context) { view.install() }

    final class HookView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            DispatchQueue.main.async { [weak self] in self?.install() }
        }

        override func layout() {
            super.layout()
            install()  // SwiftUI may show its background layers again after an update
        }

        func install() {
            guard let window, let hosting = window.contentView, let frame = hosting.superview else { return }
            window.isOpaque = false
            window.backgroundColor = .clear

            for layer in hosting.subviews where Self.isWindowBackground(layer, in: hosting) {
                layer.isHidden = true
            }
            if !frame.subviews.contains(where: { $0 is NSGlassEffectView }) {
                let glass = NSGlassEffectView(frame: frame.bounds)
                glass.autoresizingMask = [.width, .height]
                frame.addSubview(glass, positioned: .below, relativeTo: hosting)
            }
        }

        /// SwiftUI's background views: full-size, childless, with a filled layer.
        private static func isWindowBackground(_ view: NSView, in hosting: NSView) -> Bool {
            view.subviews.isEmpty
                && view.frame.size == hosting.bounds.size
                && (view.layer?.backgroundColor?.alpha ?? 0) > 0
        }
    }
}
