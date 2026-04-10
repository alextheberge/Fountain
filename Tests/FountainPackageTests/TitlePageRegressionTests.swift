import XCTest
import Fountain

/// Roadmap Phase 3.3 — title-page pre-scan must not eat body sluglines like a lone `FADE IN:`.
final class TitlePageRegressionTests: XCTestCase {
    func testLoneFadeInBeforeBlankLineIsNotTitlePageKey() {
        let script = FNScript(string: "FADE IN:\n\nINT. ROOM - DAY\n\nAction.\n")
        XCTAssertTrue(script.titlePage.isEmpty, "Lone directive-only line should not populate title page")
        let slug = script.elements.first { $0.elementType == "Scene Heading" }
        XCTAssertEqual(slug?.elementText, "INT. ROOM - DAY", "Slugline must remain in the body")
    }

    func testRealTitlePageIsParsedAndBodyRemains() {
        let script = FNScript(
            string: "Title: The Film\nCredit: A Writer\n\nFirst line of action.\n"
        )
        XCTAssertFalse(script.titlePage.isEmpty)
        let keys = Set(script.titlePage.compactMap { $0.keys.first })
        XCTAssertTrue(keys.contains("title"))
        XCTAssertTrue(keys.contains("credit"))
        XCTAssertEqual(script.elements.first?.elementType, "Action")
        XCTAssertEqual(script.elements.first?.elementText, "First line of action.")
    }
}
