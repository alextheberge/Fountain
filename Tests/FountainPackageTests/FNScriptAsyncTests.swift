import XCTest
import Fountain

final class FNScriptAsyncTests: XCTestCase {
    func testParseStringAsyncMatchesSyncParse() async {
        let source = "\nINT. ASYNC - DAY\n\nHello.\n"
        let asyncScript = await FNScript.parseStringAsync(source)
        let syncScript = FNScript(string: source)
        XCTAssertEqual(asyncScript.elements.count, syncScript.elements.count)
        XCTAssertEqual(asyncScript.elements.map(\.elementType), syncScript.elements.map(\.elementType))
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
        let fromFileCandidate = fromFile.appendingPathComponent("FountainTests/Brick And Steel.txt")
        let cwdCandidate = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("FountainTests/Brick And Steel.txt")
        if FileManager.default.fileExists(atPath: fromFileCandidate.path) { return fromFileCandidate }
        if FileManager.default.fileExists(atPath: cwdCandidate.path) { return cwdCandidate }
        return nil
    }
}
