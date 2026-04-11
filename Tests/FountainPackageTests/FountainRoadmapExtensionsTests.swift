import XCTest
import Fountain

/// Phase 6.3 / 9.2 follow-on coverage.
final class FountainRoadmapExtensionsTests: XCTestCase {
    func testInlineDelimiterTableMatchesScannerExpectations() {
        XCTAssertEqual(FountainInlineDelimiterTable.starLedEmphasis.count, 4)
        XCTAssertEqual(FountainInlineDelimiterTable.underscoreLedEmphasis.count, 3)
        XCTAssertFalse(FountainInlineDelimiterTable.italicSingleAsteriskClose.isEmpty)
    }

    func testScriptElementStreamYieldsParsedElements() async {
        let source = "\nINT. STREAM - DAY\n\nAction here.\n"
        var kinds: [ScriptElementKind] = []
        for await el in FNScript.scriptElementStream(from: source) {
            kinds.append(el.kind)
        }
        XCTAssertEqual(kinds, [.sceneHeading, .action])
    }

    func testScriptElementStreamFromFileMatchesBrickAndSteelDocument() async throws {
        var fromFile = URL(fileURLWithPath: "\(#filePath)")
        for _ in 0 ..< 3 {
            fromFile.deleteLastPathComponent()
        }
        let candidate = fromFile.appendingPathComponent("FountainTests/Resources/Brick And Steel.txt")
        let cwdCandidate = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("FountainTests/Resources/Brick And Steel.txt")
        let url: URL
        if FileManager.default.fileExists(atPath: candidate.path) {
            url = candidate
        } else if FileManager.default.fileExists(atPath: cwdCandidate.path) {
            url = cwdCandidate
        } else {
            throw XCTSkip("Brick And Steel.txt not found")
        }
        let doc = FountainDocument(script: FNScript(file: url.path))
        var index = 0
        for await el in FNScript.scriptElementStream(fromFile: url.path) {
            XCTAssertLessThan(index, doc.elements.count)
            let ref = doc.elements[index]
            XCTAssertEqual(el.kind, ref.kind, "index \(index)")
            XCTAssertEqual(el.text, ref.text, "index \(index)")
            XCTAssertEqual(el.metadata, ref.metadata, "index \(index)")
            index += 1
        }
        XCTAssertEqual(index, doc.elements.count)
    }

    /// Stream uses a fresh parse; assert structural parity with ``FountainDocument`` (ids are not stable across parses).
    func testScriptElementStreamMatchesParallelDocumentFields() async {
        let source = "\nINT. STREAM - DAY\n\nHey.\n\nANN\nHi.\n"
        let doc = FountainDocument(script: FNScript(string: source))
        var index = 0
        for await el in FNScript.scriptElementStream(from: source) {
            XCTAssertLessThan(index, doc.elements.count)
            let ref = doc.elements[index]
            XCTAssertEqual(el.kind, ref.kind, "index \(index)")
            XCTAssertEqual(el.text, ref.text, "index \(index)")
            XCTAssertEqual(el.metadata, ref.metadata, "index \(index)")
            index += 1
        }
        XCTAssertEqual(index, doc.elements.count)
    }
}
