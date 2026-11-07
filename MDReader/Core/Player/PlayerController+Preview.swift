import Foundation

extension PlayerController {
    /// A controller with made-up content, for SwiftUI previews.
    static func preview(playing: Bool = false) -> PlayerController {
        let controller = emptyPreview()
        controller.text = "# Welcome\n\nThis is **MDReader**.\n\n- Paste Markdown\n- Press play"
        controller.chunks = ["Welcome.", "This is MDReader.", "Paste Markdown.", "Press play."]
        controller.chunkStarts = [0, 1.2, 3.0, 4.6]
        controller.duration = 6
        controller.currentTime = 3.4
        controller.phase = .ready
        controller.isPlaying = playing
        return controller
    }

    /// A controller reading `markdown`, partway through paragraph `currentChunk`.
    /// Paragraph timings are estimated from their length.
    static func preview(markdown: String, currentChunk: Int) -> PlayerController {
        let controller = emptyPreview()
        controller.text = markdown
        controller.chunks = MarkdownSanitizer().paragraphs(from: markdown)
        controller.chunkStarts = controller.chunks.reduce(into: [0]) { starts, chunk in
            starts.append(starts.last! + Double(chunk.count) / 14 + paragraphGap)
        }
        controller.duration = controller.chunkStarts.removeLast()
        controller.currentTime = controller.chunkStarts[min(currentChunk, controller.chunks.count - 1)] + 1
        controller.phase = .ready
        controller.isPlaying = true
        return controller
    }

    /// A controller with nothing loaded, for SwiftUI previews.
    static func emptyPreview() -> PlayerController {
        PlayerController(cache: AudioCache(directory: .temporaryDirectory.appending(path: "MDReaderPreview")),
                         defaults: UserDefaults(suiteName: "MDReaderPreview")!)
    }
}
