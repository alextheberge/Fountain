import XCTest
import Fountain

final class FNScriptIncrementalParseTests: XCTestCase {
    func testParseIncrementalMatchesFullParseElementShape() {
        let before = "\nINT. ROOM - DAY\n\nBOB\nHello.\n"
        let after = "\nINT. ROOM - DAY\n\nBOB\nHello there.\n"
        let old = FNScript(string: before, parser: .fast)
        guard let r = after.range(of: "there") else {
            XCTFail("range")
            return
        }
        let lo = r.lowerBound.utf16Offset(in: after)
        let hi = r.upperBound.utf16Offset(in: after)
        let outcome = old.parseIncremental(newText: after, editedUTF16Range: lo..<hi, parser: .fast)
        XCTAssertEqual(outcome.reparseStrategy, .fullDocument)
        let full = FNScript(string: after, parser: .fast)
        XCTAssertEqual(outcome.script.elements.count, full.elements.count)
        for (a, b) in zip(outcome.script.elements, full.elements) {
            XCTAssertEqual(a.elementType, b.elementType)
            XCTAssertEqual(a.elementText, b.elementText)
        }
    }

    func testParseIncrementalPreservesStablePrefixAndSuffixIDs() {
        let before = "\nINT. A - DAY\n\nAction one.\n\nINT. B - DAY\n\nAction two.\n"
        let after = "\nINT. A - DAY\n\nAction one.\nEdited middle.\n\nINT. B - DAY\n\nAction two.\n"
        let old = FNScript(string: before, parser: .tokenPipeline)
        guard let r = after.range(of: "Edited") else {
            XCTFail("range")
            return
        }
        let lo = r.lowerBound.utf16Offset(in: after)
        let hi = r.upperBound.utf16Offset(in: after)
        let outcome = old.parseIncremental(newText: after, editedUTF16Range: lo..<hi, parser: .tokenPipeline)
        let fresh = FNScript(string: after, parser: .tokenPipeline)
        XCTAssertGreaterThanOrEqual(outcome.script.elements.count, 3)
        XCTAssertEqual(outcome.script.elements.first?.id, old.elements.first?.id)
        XCTAssertEqual(outcome.script.elements.last?.id, old.elements.last?.id)
        XCTAssertNotEqual(
            outcome.script.elements.last?.id,
            fresh.elements.last?.id,
            "suffix ids should be preserved from the previous parse, not regenerated like a cold parse"
        )
    }
}
