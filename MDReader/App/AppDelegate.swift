import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var keyboardShortcuts: KeyboardShortcuts?
    private var hotKey: GlobalHotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let controller = PlayerController.shared
        keyboardShortcuts = KeyboardShortcuts(controller: controller)
        hotKey = GlobalHotKey { controller.togglePlayPause() }
        _ = Updater.shared

        if #unavailable(macOS 15.0) {
            DispatchQueue.main.async(execute: closeReaderWindow)
        }
        if SelfTest.isRequested {
            SelfTest.run(controller)
        }
        if Screenshot.isRequested {
            Screenshot.render()
        }
    }

    private func closeReaderWindow() {
        NSApp.windows
            .filter { $0.identifier?.rawValue.hasPrefix(ReaderView.windowID) == true }
            .forEach { $0.close() }
    }
}
