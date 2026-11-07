/// How fenced code blocks are spoken.
enum CodeBlockMode: String, CaseIterable, Identifiable, Sendable {
    case skip
    case announce

    var id: Self { self }

    var label: String {
        switch self {
        case .skip: "Skip silently"
        case .announce: "Say “code block omitted”"
        }
    }
}

/// Turns Markdown into speakable paragraphs.
///
/// Every heading, list item, table row and paragraph becomes its own chunk and ends in sentence
/// punctuation, so the voice pauses between them instead of running them together.
struct MarkdownSanitizer: Sendable {
    static let codeBlockAnnouncement = "Code block omitted."

    var codeBlockMode: CodeBlockMode

    init(codeBlockMode: CodeBlockMode = .skip) {
        self.codeBlockMode = codeBlockMode
    }

    func paragraphs(from markdown: String) -> [String] {
        var parser = MarkdownBlockParser(codeBlockMode: codeBlockMode)
        return parser.parse(markdown)
    }

    func plainText(from markdown: String) -> String {
        paragraphs(from: markdown).joined(separator: "\n\n")
    }
}
