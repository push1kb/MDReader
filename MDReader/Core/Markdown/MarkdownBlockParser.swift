/// Reads Markdown line by line, turning block structure into spoken paragraphs.
struct MarkdownBlockParser {
    private typealias Pattern = MarkdownPattern

    let codeBlockMode: CodeBlockMode
    private var output: [String] = []
    private var paragraph: [String] = []
    private var openFence: (marker: Character, length: Int)?
    private var inTable = false

    init(codeBlockMode: CodeBlockMode) {
        self.codeBlockMode = codeBlockMode
    }

    mutating func parse(_ markdown: String) -> [String] {
        let lines = markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacing(Pattern.htmlComment, with: "")
            .components(separatedBy: "\n")

        for (index, line) in lines.enumerated() {
            consume(line, next: lines.indices.contains(index + 1) ? lines[index + 1] : nil)
        }
        flushParagraph()
        return output
    }

    private mutating func consume(_ rawLine: String, next: String?) {
        if openFence != nil {
            closeFence(on: rawLine)
            return
        }
        if openFence(on: rawLine) { return }

        let (line, isQuoted) = Self.strippingBlockquote(rawLine)

        if line.allSatisfy(\.isWhitespace) {
            flushParagraph()
            inTable = false
        } else if line.wholeMatch(of: Pattern.referenceDefinition) != nil {
            return
        } else if !paragraph.isEmpty, !isQuoted, line.wholeMatch(of: Pattern.setextUnderline) != nil {
            flushParagraph()
        } else if line.wholeMatch(of: Pattern.horizontalRule) != nil {
            flushParagraph()
        } else if let heading = line.wholeMatch(of: Pattern.atxHeading) {
            flushParagraph()
            emit(heading.output.1.map(String.init) ?? "")
        } else if consumeTableRow(line, next: next) {
            return
        } else {
            inTable = false
            if let footnote = line.wholeMatch(of: Pattern.footnoteDefinition) {
                startParagraph(String(footnote.output.1))
            } else if let item = line.wholeMatch(of: Pattern.listItem) {
                startParagraph(String(item.output.1))
            } else {
                paragraph.append(line.trimmingCharacters(in: .whitespaces))
            }
        }
    }

    // MARK: Code fences

    private mutating func openFence(on line: String) -> Bool {
        guard let match = line.wholeMatch(of: Pattern.fence), let marker = match.output.1.first else { return false }
        flushParagraph()
        openFence = (marker, match.output.1.count)
        if codeBlockMode == .announce {
            output.append(MarkdownSanitizer.codeBlockAnnouncement)
        }
        return true
    }

    private mutating func closeFence(on line: String) {
        guard let fence = openFence, let match = line.wholeMatch(of: Pattern.fence) else { return }
        let marker = match.output.1
        if marker.first == fence.marker, marker.count >= fence.length, match.output.2.allSatisfy(\.isWhitespace) {
            openFence = nil
        }
    }

    // MARK: Tables

    private mutating func consumeTableRow(_ line: String, next: String?) -> Bool {
        guard line.contains("|") else { return false }

        if line.wholeMatch(of: Pattern.tableSeparator) != nil {
            flushParagraph()
            inTable = true
            return true
        }

        let startsTable = next?.wholeMatch(of: Pattern.tableSeparator) != nil
        let hasLeadingPipe = line.trimmingCharacters(in: .whitespaces).hasPrefix("|")
        guard inTable || startsTable || hasLeadingPipe else { return false }

        flushParagraph()
        inTable = true
        let cells = Self.cells(of: line).map(InlineMarkdown.strip).filter { !$0.isEmpty }
        if !cells.isEmpty {
            emitSpoken(cells.joined(separator: ", "))
        }
        return true
    }

    /// Splits a table row on unescaped pipes.
    private static func cells(of row: String) -> [String] {
        var cells: [String] = []
        var cell = ""
        var previous: Character?
        for character in row {
            if character == "|", previous != "\\" {
                cells.append(cell)
                cell = ""
            } else {
                cell.append(character)
            }
            previous = character
        }
        cells.append(cell)
        return cells.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    // MARK: Output

    private static func strippingBlockquote(_ line: String) -> (line: String, isQuoted: Bool) {
        var rest = Substring(line)
        var isQuoted = false
        while let marker = rest.prefixMatch(of: Pattern.blockquote) {
            rest = rest[marker.range.upperBound...]
            isQuoted = true
        }
        return (String(rest), isQuoted)
    }

    private mutating func startParagraph(_ text: String) {
        flushParagraph()
        paragraph = [text]
    }

    private mutating func flushParagraph() {
        guard !paragraph.isEmpty else { return }
        emit(paragraph.joined(separator: " "))
        paragraph = []
    }

    private mutating func emit(_ markdown: String) {
        emitSpoken(InlineMarkdown.strip(markdown))
    }

    private mutating func emitSpoken(_ text: String) {
        guard text.contains(where: { $0.isLetter || $0.isNumber }) else { return }
        output.append(InlineMarkdown.endingSentence(text))
    }
}
