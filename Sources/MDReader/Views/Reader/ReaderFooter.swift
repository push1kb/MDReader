import MDReaderCore
import SwiftUI

/// Export, Open in Window, the global hot key hint and Quit.
struct ReaderFooter: View {
    let controller: PlayerController
    let showsOpenInWindow: Bool
    let onExportError: (String) -> Void

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        HStack {
            Button("Export Audio…") {
                ExportPanel.present(for: controller, onError: onExportError)
            }
            .disabled(!controller.hasAudio)

            if showsOpenInWindow {
                Button("Open in Window") {
                    openWindow(id: ReaderView.windowID)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }

            Spacer()

            Text("Global: \(GlobalHotKey.displayName)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .help("Play or pause from any app")

            Button("Quit") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
        .controlSize(.small)
    }
}

#Preview {
    ReaderFooter(controller: .preview(), showsOpenInWindow: true) { _ in }
        .padding()
        .frame(width: 420)
}
