import XCTest
import Fountain

/// Phase 7.1 — **Brick & Steel** reference screenplay (title-page emphasis + dual dialogue) parses at scale.
final class BrickSteelCorpusTests: XCTestCase {
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

    func testBrickAndSteelParsesWithDualDialogueAndManyElements() throws {
        let url = try XCTUnwrap(brickSteelURL(), "Brick And Steel.txt not found (run `swift test` from repo root)")
        let script = FNScript(file: url.path)
        XCTAssertGreaterThan(script.elements.count, 40, "Brick & Steel should yield a substantial element count")
        let dualChars = script.elements.filter { $0.elementType == "Character" && $0.isDualDialogue }
        XCTAssertGreaterThanOrEqual(dualChars.count, 2, "Expect at least one dual-dialogue pair (BRICK ^ / STEEL)")
    }

    /// Phase 7.2 — title page, metrics, and JSON export stay consistent on a reference corpus.
    func testBrickAndSteelTitlePageMetricsAndJSONRoundTrip() throws {
        let url = try XCTUnwrap(brickSteelURL(), "Brick And Steel.txt not found (run `swift test` from repo root)")
        let script = FNScript(file: url.path)
        XCTAssertFalse(script.titlePage.isEmpty, "Brick & Steel includes a title block")
        let m = script.metrics
        XCTAssertEqual(m.elementCount, script.elements.count)
        XCTAssertEqual(m.elementCountExcludingBoneyard, script.elementsExcludingBoneyard.count)
        XCTAssertGreaterThan(m.wordCountExcludingBoneyard, 200, "Sanity word volume")
        XCTAssertGreaterThan(m.dialogueWordCount, 15, "Sanity dialogue volume")

        let data = try script.fountainDocumentJSONData()
        let decoded = try JSONDecoder().decode(FountainDocument.self, from: data)
        ParseAssertions.assertFountainDocumentsStructurallyEqual(decoded, script.asFountainDocument())
    }
}
