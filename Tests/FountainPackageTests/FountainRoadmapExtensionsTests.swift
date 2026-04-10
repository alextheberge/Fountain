import XCTest
import Fountain

/// Phase 6.3 / 8.4 / 9.2 follow-on coverage.
final class FountainRoadmapExtensionsTests: XCTestCase {
    func testInlineDelimiterTableMatchesScannerExpectations() {
        XCTAssertEqual(FountainInlineDelimiterTable.starLedEmphasis.count, 4)
        XCTAssertEqual(FountainInlineDelimiterTable.underscoreLedEmphasis.count, 3)
        XCTAssertFalse(FountainInlineDelimiterTable.italicSingleAsteriskClose.isEmpty)
    }

    func testStubRenderersThrowNotImplemented() {
        let script = FNScript(string: "Title: X\n\nINT. R - DAY\n")
        XCTAssertThrowsError(try FountainFDXWriter().render(script)) { err in
            XCTAssertEqual(err as? FountainStubRendererError, .notImplemented("FountainFDXWriter"))
        }
        XCTAssertThrowsError(try FountainPDFWriter().render(script)) { err in
            XCTAssertEqual(err as? FountainStubRendererError, .notImplemented("FountainPDFWriter"))
        }
    }

    func testScriptElementStreamYieldsParsedElements() async {
        let source = "\nINT. STREAM - DAY\n\nAction here.\n"
        var kinds: [ScriptElementKind] = []
        for await el in FNScript.scriptElementStream(from: source) {
            kinds.append(el.kind)
        }
        XCTAssertEqual(kinds, [.sceneHeading, .action])
    }
}
