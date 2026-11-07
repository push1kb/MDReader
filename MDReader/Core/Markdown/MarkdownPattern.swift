// `nonisolated(unsafe)`: Regex isn't Sendable, but these are immutable and only ever read.

enum MarkdownPattern {
    // MARK: Blocks

    nonisolated(unsafe) static let fence = /^ {0,3}(`{3,}|~{3,})(.*)$/
    nonisolated(unsafe) static let blockquote = /^ {0,3}> ?/
    nonisolated(unsafe) static let atxHeading = /^ {0,3}#{1,6}(?:[ \t]+(.*?))??(?:[ \t]+#+)?[ \t]*$/
    nonisolated(unsafe) static let setextUnderline = /^ {0,3}(?:=+|-+)[ \t]*$/
    nonisolated(unsafe) static let horizontalRule = /^ {0,3}(?:(?:\*[ \t]*){3,}|(?:-[ \t]*){3,}|(?:_[ \t]*){3,})$/
    nonisolated(unsafe) static let tableSeparator = /^[ \t]*\|?[ \t]*:?-+:?[ \t]*(?:\|[ \t]*:?-+:?[ \t]*)*\|?[ \t]*$/
    nonisolated(unsafe) static let listItem = /^[ \t]*(?:[-*+]|\d{1,9}[.)])[ \t]+(?:\[[ xX]\][ \t]+)?(.*)$/
    nonisolated(unsafe) static let footnoteDefinition = /^ {0,3}\[\^[^\]]+\]:[ \t]*(.*)$/
    nonisolated(unsafe) static let referenceDefinition = /^ {0,3}\[[^\]^][^\]]*\]:[ \t]*\S+.*$/
    nonisolated(unsafe) static let htmlComment = /<!--[\s\S]*?-->/

    // MARK: Inline

    nonisolated(unsafe) static let escape = /\\([\\`*_{}\[\]()#+\-.!|~<>])/
    nonisolated(unsafe) static let escapePlaceholder = /\x{E000}(\d+)\x{E001}/
    nonisolated(unsafe) static let inlineCode = /(`+)(.+?)\1/
    nonisolated(unsafe) static let image = /!\[([^\]]*)\]\([^)]*\)/
    nonisolated(unsafe) static let referenceImage = /!\[([^\]]*)\]\[[^\]]*\]/
    nonisolated(unsafe) static let link = /\[([^\]]+)\]\([^)]*\)/
    nonisolated(unsafe) static let referenceLink = /\[([^\]^][^\]]*)\]\[[^\]]*\]/
    nonisolated(unsafe) static let parenthesizedURL = /\(\s*<?(?:https?:\/\/|www\.)[^\s()]*>?\s*\)/
    nonisolated(unsafe) static let autolink = /<(?:https?|ftp|mailto):[^>\s]+>/
    nonisolated(unsafe) static let bareURL = /(?:https?:\/\/|www\.)[^\s<>()]+[^\s<>().,;:!?'"]/
    nonisolated(unsafe) static let footnoteMarker = /\[\^[^\]]+\]/
    nonisolated(unsafe) static let lineBreakTag = /<br\s*\/?>/.ignoresCase()
    nonisolated(unsafe) static let htmlTag = /<\/?[A-Za-z][A-Za-z0-9-]*(?:\s[^<>]*)?\/?>/
    nonisolated(unsafe) static let strikethrough = /~~(.+?)~~/
    nonisolated(unsafe) static let starEmphasis = /(\*{1,3})(\S(?:.*?\S)?)\1/
    // Swift Regex has no lookbehind, so the character before the underscores is captured instead.
    nonisolated(unsafe) static let underscoreEmphasis = /(^|[^A-Za-z0-9_])(_{1,3})(\S(?:.*?\S)?)\2(?![A-Za-z0-9_])/
    nonisolated(unsafe) static let whitespace = /\s+/
    nonisolated(unsafe) static let spaceBeforePunctuation = /\ +([.,;:!?])/
}
