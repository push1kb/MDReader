import MDReaderCore
import SwiftUI

@main
struct MDReaderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let controller = PlayerController.shared

    var body: some Scene {
        MenuBarExtra("MDReader", systemImage: controller.isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2") {
            ReaderView(controller: controller, presentation: .panel)
        }
        .menuBarExtraStyle(.window)

        Window("MDReader", id: ReaderView.windowID) {
            ReaderView(controller: controller, presentation: .window)
        }
        .defaultSize(width: 720, height: 820)
        .windowResizability(.contentMinSize)
        .closedAtLaunch()
    }
}

extension PlayerController {
    /// The controller behind the menu bar panel and the reader window.
    static let shared = PlayerController()
}

private extension Scene {
    /// Keeps the reader window from opening at launch. macOS 14 lacks the API;
    /// `AppDelegate` closes the window there instead.
    func closedAtLaunch() -> some Scene {
        if #available(macOS 15.0, *) {
            return defaultLaunchBehavior(.suppressed)
        } else {
            return self
        }
    }
}
