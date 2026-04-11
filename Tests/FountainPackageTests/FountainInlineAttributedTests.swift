import XCTest
import Foundation
import Fountain

final class FountainInlineAttributedTests: XCTestCase {
    func testAttributedBoldPreservesCharacters() {
        let a = FountainInlineMarkup.attributedFragment(from: "pre **mid** post")
        XCTAssertEqual(String(a.characters), "pre mid post")
        XCTAssertNotNil(a.runs.first { $0.inlinePresentationIntent?.contains(.stronglyEmphasized) == true })
    }

    func testAttributedItalicSingleStar() {
        let a = FountainInlineMarkup.attributedFragment(from: "say *hi* there")
        XCTAssertEqual(String(a.characters), "say hi there")
        XCTAssertNotNil(a.runs.first { $0.inlinePresentationIntent?.contains(.emphasized) == true })
    }

    func testAttributedMatchesHtmlStructureForBoldItalic() {
        let s = "***BI***"
        let html = FountainInlineMarkup.htmlFragment(from: s)
        let attr = FountainInlineMarkup.attributedFragment(from: s)
        XCTAssertTrue(html.contains("<strong>"))
        XCTAssertEqual(String(attr.characters), "BI")
    }
}
