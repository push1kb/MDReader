import AppKit
import UniformTypeIdentifiers

/// Asks where to save the generated audio, then exports it as .m4a and reveals it in Finder.
@MainActor
enum ExportPanel {
    static func present(for controller: PlayerController, onError: @escaping (String) -> Void) {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.mpeg4Audio]
        panel.nameFieldStringValue = fileName(from: controller.chunks.first)
        panel.canCreateDirectories = true
        panel.level = .floating

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            Task {
                do {
                    try await controller.exportAudio(to: url)
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                } catch {
                    onError(error.localizedDescription)
                }
            }
        }
    }

    /// The document's first paragraph — usually its title — as a file name.
    private static func fileName(from title: String?) -> String {
        let name = (title ?? "MDReader")
            .trimmingCharacters(in: CharacterSet(charactersIn: ".!?:; "))
            .components(separatedBy: CharacterSet(charactersIn: "/:\\"))
            .joined(separator: "-")
        return String(name.prefix(60)) + ".m4a"
    }
}
