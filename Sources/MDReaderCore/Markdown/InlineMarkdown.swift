/// Removes inline Markdown and HTML from a line or paragraph, leaving the words to be spoken.
enum InlineMarkdown {
    private typealias Pattern = MarkdownPattern

    static func strip(_ markdown: String) -> String {
        let (text, escaped) = protectingEscapes(in: markdown)
        let spoken = decodingEntities(in: text
            .replacing(Pattern.inlineCode) { String($0.output.2) }
            .replacing(Pattern.image) { String($0.output.1) }
            .replacing(Pattern.referenceImage) { String($0.output.1) }
            .replacing(Pattern.link) { String($0.output.1) }
            .replacing(Pattern.referenceLink) { String($0.output.1) }
            .replacing(Pattern.parenthesizedURL, with: "")
            .replacing(Pattern.autolink, with: "")
            .replacing(Pattern.bareURL, with: "")
            .replacing(Pattern.footnoteMarker, with: "")
            .replacing(Pattern.lineBreakTag, with: " ")
            .replacing(Pattern.htmlTag, with: ""))
            .replacing(Pattern.strikethrough) { String($0.output.1) }
            .replacing(Pattern.starEmphasis) { String($0.output.2) }
            .replacing(Pattern.underscoreEmphasis) { String($0.output.1) + String($0.output.3) }

        return restoringEscapes(escaped, in: spoken)
            .replacing(Pattern.whitespace, with: " ")
            .replacing(Pattern.spaceBeforePunctuation) { String($0.output.1) }
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Adds a full stop unless the text already ends a sentence, so the voice pauses after it.
    static func endingSentence(_ text: String) -> String {
        guard let last = text.last else { return text }
        if ".!?:;…".contains(last) { return text }
        if "\"')]”’".contains(last), let previous = text.dropLast().last, ".!?".contains(previous) {
            return text
        }
        return text + "."
    }

    // MARK: Escapes

    /// Swaps backslash-escaped characters for placeholders so no pattern treats them as markup.
    private static func protectingEscapes(in text: String) -> (text: String, escaped: [Substring]) {
        var escaped: [Substring] = []
        let protected = text.replacing(Pattern.escape) { match in
            escaped.append(match.output.1)
            return "\u{E000}\(escaped.count - 1)\u{E001}"
        }
        return (protected, escaped)
    }

    private static func restoringEscapes(_ escaped: [Substring], in text: String) -> String {
        text.replacing(Pattern.escapePlaceholder) { match in
            Int(match.output.1).flatMap { escaped.indices.contains($0) ? String(escaped[$0]) : nil } ?? ""
        }
    }

    // MARK: HTML entities

    private static let entities: [(entity: String, character: String)] = [
        ("&nbsp;", " "), ("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""), ("&#39;", "'"),
        ("&apos;", "'"), ("&mdash;", "—"), ("&ndash;", "–"), ("&hellip;", "…"),
        ("&amp;", "&"),  // last, so "&amp;lt;" becomes "&lt;" rather than "<"
    ]

    private static func decodingEntities(in text: String) -> String {
        guard text.contains("&") else { return text }
        return entities.reduce(text) { $0.replacingOccurrences(of: $1.entity, with: $1.character) }
    }
}
