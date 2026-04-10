import XCTest
import Fountain

/// Phase 4.4 + 7.2 — centered `> ... <` vs forced transition `>` (no closing `<`).
final class ParseStructureTests: XCTestCase {
    func testCenteredVersusForcedTransition() {
        ParseAssertions.assertElementTypes(
            FNScript(string: "> CENTERED LINE <\n\n> CUT TO: KITCHEN\n"),
            [.action, .transition]
        )
        XCTAssertTrue(FNScript(string: "> CENTERED LINE <\n").elements.first?.isCentered == true)
        XCTAssertTrue(FNScript(string: "> CUT TO:\n").elements.first?.isCentered == false)
    }

    func testFountainDocumentInitFromScriptMatchesAsFountainDocument() {
        let script = FNScript(string: "INT. Z - DAY\n\nHello.\n")
        let a = script.asFountainDocument()
        let b = FountainDocument(script: script)
        XCTAssertEqual(a.elements.map(\.kind), b.elements.map(\.kind))
        XCTAssertEqual(a.titlePage.count, b.titlePage.count)
    }
}
