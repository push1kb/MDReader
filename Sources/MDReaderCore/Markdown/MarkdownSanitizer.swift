/// How fenced code blocks are spoken.
public enum CodeBlockMode: String, CaseIterable, Identifiable, Sendable {
    case skip
    case announce

    public var id: Self { self }

    public var label: String {
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
public struct MarkdownSanitizer: Sendable {
    public static let codeBlockAnnouncement = "Code block omitted."

    public var codeBlockMode: CodeBlockMode

    public init(codeBlockMode: CodeBlockMode = .skip) {
        self.codeBlockMode = codeBlockMode
    }

    public func paragraphs(from markdown: String) -> [String] {
        var parser = MarkdownBlockParser(codeBlockMode: codeBlockMode)
        return parser.parse(markdown)
    }

    public func plainText(from markdown: String) -> String {
        paragraphs(from: markdown).joined(separator: "\n\n")
    }
}
