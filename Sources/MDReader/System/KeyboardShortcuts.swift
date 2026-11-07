import AppKit
import MDReaderCore

/// Playback keys for whenever an MDReader window is focused, except while typing in the editor.
///
/// Space play/pause · ←/→ ∓10 s · ⇧←/⇧→ previous/next paragraph · ⌘↑/⌘↓ speed
@MainActor
final class KeyboardShortcuts {
    private enum Key {
        static let space: UInt16 = 49
        static let left: UInt16 = 123
        static let right: UInt16 = 124
        static let down: UInt16 = 125
        static let up: UInt16 = 126
    }

    private var monitor: Any?

    init(controller: PlayerController) {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak controller] event in
            let key = event.keyCode
            // Not `.deviceIndependentFlagsMask`: arrow keys always carry `.function` and `.numericPad`.
            let modifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])
            let handled = MainActor.assumeIsolated {
                controller.map { Self.handle(key, modifiers, on: $0) } ?? false
            }
            return handled ? nil : event
        }
    }

    deinit {
        if let monitor { NSEvent.removeMonitor(monitor) }
    }

    private static func handle(_ key: UInt16, _ modifiers: NSEvent.ModifierFlags, on controller: PlayerController) -> Bool {
        guard !(NSApp.keyWindow?.firstResponder is NSText) else { return false }

        switch (key, modifiers) {
        case (Key.space, []): controller.togglePlayPause()
        case (Key.left, []): controller.skip(by: -PlayerController.skipInterval)
        case (Key.right, []): controller.skip(by: PlayerController.skipInterval)
        case (Key.left, .shift): controller.previousParagraph()
        case (Key.right, .shift): controller.nextParagraph()
        case (Key.up, .command): controller.adjustRate(by: PlayerController.speedStep)
        case (Key.down, .command): controller.adjustRate(by: -PlayerController.speedStep)
        default: return false
        }
        return true
    }
}
