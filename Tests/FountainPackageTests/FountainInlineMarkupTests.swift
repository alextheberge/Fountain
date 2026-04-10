import XCTest
import Fountain

/// Phase 6.2 — linear-scan inline emphasis (golden HTML fragments).
final class FountainInlineMarkupTests: XCTestCase {
    func testBoldItalicUnderlineComboMarkers() {
        XCTAssertEqual(
            FountainInlineMarkup.htmlFragment(from: "_***BIU***_"),
            "<strong><em><u>BIU</u></em></strong>"
        )
        XCTAssertEqual(
            FountainInlineMarkup.htmlFragment(from: "***_BIU_***"),
            "<strong><em><u>BIU</u></em></strong>"
        )
    }

    func testBoldItalicBoldUnderlineItalicUnderlineBoldItalicUnderline() {
        XCTAssertEqual(
            FountainInlineMarkup.htmlFragment(from: "***BI***"),
            "<strong><em>BI</em></strong>"
        )
        XCTAssertEqual(
            FountainInlineMarkup.htmlFragment(from: "**_BU_**"),
            "<strong><u>BU</u></strong>"
        )
        XCTAssertEqual(
            FountainInlineMarkup.htmlFragment(from: "_*IU*_"),
            "<em><u>IU</u></em>"
        )
    }

    func testBoldItalicUnderlineSingleDelimiters() {
        XCTAssertEqual(FountainInlineMarkup.htmlFragment(from: "**B**"), "<strong>B</strong>")
        XCTAssertEqual(FountainInlineMarkup.htmlFragment(from: "*I*"), "<em>I</em>")
        XCTAssertEqual(FountainInlineMarkup.htmlFragment(from: "_U_"), "<u>U</u>")
    }

    func testEscapesHtmlSpecialCharactersInsideAndOutsideSpans() {
        XCTAssertEqual(
            FountainInlineMarkup.htmlFragment(from: "a & b **c < d**"),
            "a &amp; b **c &lt; d**"
        )
    }

    func testBackslashEscapesAsterisk() {
        XCTAssertEqual(FountainInlineMarkup.htmlFragment(from: #"\*not italic\*"#), "*not italic*")
    }

    func testAngleBracketsAbortEmphasisSpanLikeLegacy() {
        XCTAssertEqual(
            FountainInlineMarkup.htmlFragment(from: "**no < close"),
            "**no &lt; close"
        )
    }
}
