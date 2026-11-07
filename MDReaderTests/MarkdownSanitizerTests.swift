import XCTest
@testable import MDReader

final class MarkdownSanitizerTests: XCTestCase {
    private let skip = MarkdownSanitizer(codeBlockMode: .skip)
    private let announce = MarkdownSanitizer(codeBlockMode: .announce)

    func testHeadingsBecomeTerminatedParagraphs() {
        XCTAssertEqual(skip.paragraphs(from: "# Title\n## Sub Title ##\nBody text"),
                       ["Title.", "Sub Title.", "Body text."])
    }

    func testSetextHeadings() {
        XCTAssertEqual(skip.paragraphs(from: "Big Title\n=========\n\nSmall\n-----\ntext"),
                       ["Big Title.", "Small.", "text."])
    }

    func testHashWithoutSpaceIsNotHeading() {
        XCTAssertEqual(skip.paragraphs(from: "#hashtag stays"), ["#hashtag stays."])
    }

    func testEmphasisStrikethroughAndInlineCode() {
        XCTAssertEqual(skip.paragraphs(from: "Some **bold**, *italic*, ___both___, ~~gone~~ and `code()` here"),
                       ["Some bold, italic, both, gone and code() here."])
    }

    func testIntrawordUnderscoresSurvive() {
        XCTAssertEqual(skip.paragraphs(from: "Call snake_case_name and _this_ one"),
                       ["Call snake_case_name and this one."])
    }

    func testArithmeticAsterisksSurvive() {
        XCTAssertEqual(skip.paragraphs(from: "Compute 5 * 3 now"), ["Compute 5 * 3 now."])
    }

    func testLinksImagesAndURLs() {
        let md = "See [the docs](https://x.com/a) and ![a cat](cat.png) ![](blank.png) at https://example.com/path. Or <https://auto.link>."
        XCTAssertEqual(skip.paragraphs(from: md), ["See the docs and a cat at. Or."])
    }

    func testReferenceLinksAndDefinitions() {
        XCTAssertEqual(skip.paragraphs(from: "Read [the guide][g] now.\n\n[g]: https://example.com/guide"),
                       ["Read the guide now."])
    }

    func testFencedCodeSkipped() {
        let md = "Before\n\n```swift\nlet x = 1 // # not a heading\n```\n\nAfter"
        XCTAssertEqual(skip.paragraphs(from: md), ["Before.", "After."])
    }

    func testFencedCodeAnnounced() {
        let md = "Before\n~~~\ncode\n~~~\nAfter"
        XCTAssertEqual(announce.paragraphs(from: md), ["Before.", MarkdownSanitizer.codeBlockAnnouncement, "After."])
    }

    func testLongerFenceNeedsMatchingClose() {
        let md = "````\n```\ninner\n```\n````\nDone"
        XCTAssertEqual(skip.paragraphs(from: md), ["Done."])
    }

    func testUnclosedFenceSwallowsRest() {
        XCTAssertEqual(skip.paragraphs(from: "Intro\n```\nnever closed\nstill code"), ["Intro."])
    }

    func testListsEachItemIsAChunk() {
        let md = "- one\n* two\n+ three\n1. four\n2) five\n- [x] done task"
        XCTAssertEqual(skip.paragraphs(from: md), ["one.", "two.", "three.", "four.", "five.", "done task."])
    }

    func testListItemContinuationLine() {
        XCTAssertEqual(skip.paragraphs(from: "- first line\n  continues here\n- second"),
                       ["first line continues here.", "second."])
    }

    func testBlockquotes() {
        XCTAssertEqual(skip.paragraphs(from: "> Quoted text\n> continues.\n>\n> > Nested"),
                       ["Quoted text continues.", "Nested."])
    }

    func testTableRowsReadAsCommaSeparated() {
        let md = """
        | Name | Score |
        |:-----|------:|
        | Ann  | 10    |
        | Bob  | **9** |
        """
        XCTAssertEqual(skip.paragraphs(from: md), ["Name, Score.", "Ann, 10.", "Bob, 9."])
    }

    func testTableWithoutOuterPipes() {
        XCTAssertEqual(skip.paragraphs(from: "a | b\n--|--\n1 | 2"), ["a, b.", "1, 2."])
    }

    func testHTMLTagsCommentsAndEntities() {
        let md = "<div>Hello <b>world</b><br>next &amp; last</div>\n<!-- hidden\ncomment -->"
        XCTAssertEqual(skip.paragraphs(from: md), ["Hello world next & last."])
    }

    func testFootnotes() {
        XCTAssertEqual(skip.paragraphs(from: "A claim[^1] here.\n\n[^1]: The source."),
                       ["A claim here.", "The source."])
    }

    func testHorizontalRulesDropped() {
        XCTAssertEqual(skip.paragraphs(from: "One\n\n---\n\n* * *\n\nTwo"), ["One.", "Two."])
    }

    func testEscapedCharactersAreLiteral() {
        XCTAssertEqual(skip.paragraphs(from: #"Not \*emphasis\* and 3 \_x\_"#), ["Not *emphasis* and 3 _x_."])
    }

    func testParagraphsJoinSoftWrappedLines() {
        XCTAssertEqual(skip.paragraphs(from: "Line one\nline two!\n\nNext para?"),
                       ["Line one line two!", "Next para?"])
    }

    func testPunctuationOnlyChunksDropped() {
        XCTAssertEqual(skip.paragraphs(from: "![](x.png)\n\n- \n\n|---|---|\n\nReal"), ["Real."])
    }

    func testWindowsLineEndings() {
        XCTAssertEqual(skip.paragraphs(from: "# Head\r\n\r\nBody\r\n"), ["Head.", "Body."])
    }

    func testRepresentativeDocument() {
        let md = """
        # Release Notes

        Version **2.0** adds [streaming](https://example.com/streaming).

        ## Changes
        - Faster _startup_
        - New `--flag` option

        ```bash
        make install
        ```

        | Platform | Status |
        |---|---|
        | macOS | ✅ |

        > Note: see https://example.com for details.
        """
        XCTAssertEqual(skip.paragraphs(from: md), [
            "Release Notes.",
            "Version 2.0 adds streaming.",
            "Changes.",
            "Faster startup.",
            "New --flag option.",
            "Platform, Status.",
            "macOS, ✅.",
            "Note: see for details.",
        ])
        XCTAssertEqual(skip.plainText(from: "# A\n\nB"), "A.\n\nB.")
    }
}
