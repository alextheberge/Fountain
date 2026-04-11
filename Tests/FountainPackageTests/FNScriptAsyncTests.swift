import XCTest
import Fountain

/// Phase 9.1 — async full parse parity vs synchronous ``FNScript``; Phase 9.2 — stream aligned with ``parseStringAsync`` snapshot.
final class FNScriptAsyncTests: XCTestCase {
    func testParseStringAsyncMatchesSyncParse() async {
        let source = "\nINT. ASYNC - DAY\n\nHello.\n"
        let asyncScript = await FNScript.parseStringAsync(source)
        let syncScript = FNScript(string: source)
        XCTAssertEqual(asyncScript.elements.count, syncScript.elements.count)
        XCTAssertEqual(asyncScript.elements.map(\.elementType), syncScript.elements.map(\.elementType))
    }

    func testParseStringAsyncTokenPipelineMatchesSyncTokenPipeline() async {
        let source = "\nINT. ASYNC TP - DAY\n\nCAROL\nHi.\n"
        let asyncScript = await FNScript.parseStringAsync(source, parser: .tokenPipeline)
        let syncScript = FNScript(string: source, parser: .tokenPipeline)
        XCTAssertEqual(asyncScript.elements.map(\.elementType), syncScript.elements.map(\.elementType))
        XCTAssertEqual(asyncScript.elements.map(\.elementText), syncScript.elements.map(\.elementText))
    }

    func testParseFileAsyncTokenPipelineMatchesSyncTokenPipeline() async throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "package-roundtrip-sample", withExtension: "fountain"))
        let asyncScript = await FNScript.parseFileAsync(url.path, parser: .tokenPipeline)
        let syncScript = FNScript(file: url.path, parser: .tokenPipeline)
        XCTAssertEqual(asyncScript.elements.map(\.elementType), syncScript.elements.map(\.elementType))
    }

    /// ``scriptElementStream(from:)`` must match a ``FountainDocument`` built from the same ``parseStringAsync`` parse (Phase 9.2 + detached parse path).
    func testScriptElementStreamFromMatchesParseStringAsyncDocument() async {
        let source = "\nINT. STREAM - DAY\n\nALICE\nOne.\n\nBOB\nTwo.\n"
        let script = await FNScript.parseStringAsync(source)
        let expected = FountainDocument(script: script).elements.map { ($0.kind, $0.text, $0.metadata) }
        var got: [(ScriptElementKind, String, [String: String])] = []
        for await el in FNScript.scriptElementStream(from: source) {
            got.append((el.kind, el.text, el.metadata))
        }
        XCTAssertEqual(got.count, expected.count)
        for i in 0 ..< got.count {
            XCTAssertEqual(got[i].0, expected[i].0, "index \(i)")
            XCTAssertEqual(got[i].1, expected[i].1, "index \(i)")
            XCTAssertEqual(got[i].2, expected[i].2, "index \(i)")
        }
    }

    func testScriptElementStreamTokenPipelineMatchesDocument() async {
        let source = "\nINT. STREAM TP - DAY\n\nALICE\nOne.\n"
        let script = await FNScript.parseStringAsync(source, parser: .tokenPipeline)
        let expected = FountainDocument(script: script).elements.map { ($0.kind, $0.text, $0.metadata) }
        var got: [(ScriptElementKind, String, [String: String])] = []
        for await el in FNScript.scriptElementStream(from: source, parser: .tokenPipeline) {
            got.append((el.kind, el.text, el.metadata))
        }
        XCTAssertEqual(got.count, expected.count)
        for i in 0 ..< got.count {
            XCTAssertEqual(got[i].0, expected[i].0, "index \(i)")
            XCTAssertEqual(got[i].1, expected[i].1, "index \(i)")
            XCTAssertEqual(got[i].2, expected[i].2, "index \(i)")
        }
    }

    /// Corpus-scale: async file parse must match sync ``init(file:)`` (Phase 9.1 + distribution smoke).
    func testParseFileAsyncMatchesSyncBrickAndSteel() async throws {
        let url = try XCTUnwrap(brickSteelURL(), "Brick And Steel.txt not found (run `swift test` from repo root)")
        let asyncScript = await FNScript.parseFileAsync(url.path)
        let syncScript = FNScript(file: url.path)
        XCTAssertEqual(asyncScript.elements.count, syncScript.elements.count)
        XCTAssertEqual(asyncScript.elements.map(\.elementType), syncScript.elements.map(\.elementType))
        XCTAssertEqual(asyncScript.titlePage.count, syncScript.titlePage.count)
    }

    private func brickSteelURL() -> URL? {
        var fromFile = URL(fileURLWithPath: "\(#filePath)")
        for _ in 0 ..< 3 {
            fromFile.deleteLastPathComponent()
        }
        let fromFileCandidate = fromFile.appendingPathComponent("FountainTests/Resources/Brick And Steel.txt")
        let cwdCandidate = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("FountainTests/Resources/Brick And Steel.txt")
        if FileManager.default.fileExists(atPath: fromFileCandidate.path) { return fromFileCandidate }
        if FileManager.default.fileExists(atPath: cwdCandidate.path) { return cwdCandidate }
        return nil
    }
}
