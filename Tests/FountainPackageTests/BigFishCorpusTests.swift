import XCTest
import Fountain

/// Phase 3.5 / 7.1 — corpus smoke: parse **Big Fish** from the Xcode test bundle path and assert scale.
final class BigFishCorpusTests: XCTestCase {
    private func bigFishURL() -> URL? {
        var fromFile = URL(fileURLWithPath: "\(#filePath)")
        for _ in 0 ..< 3 {
            fromFile.deleteLastPathComponent()
        }
        let fromFileCandidate = fromFile.appendingPathComponent("FountainTests/Resources/Big Fish.fountain")
        let cwdCandidate = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("FountainTests/Resources/Big Fish.fountain")
        if FileManager.default.fileExists(atPath: fromFileCandidate.path) { return fromFileCandidate }
        if FileManager.default.fileExists(atPath: cwdCandidate.path) { return cwdCandidate }
        return nil
    }

    func testBigFishParsesWithManyElements() throws {
        let url = try XCTUnwrap(bigFishURL(), "Big Fish.fountain not found (run `swift test` from repo root)")
        let script = FNScript(file: url.path)
        XCTAssertGreaterThan(script.elements.count, 500, "Sanity: Big Fish should yield hundreds of elements")
    }

    func testBigFishMetricsAndDocumentJSONRoundTrip() throws {
        let url = try XCTUnwrap(bigFishURL(), "Big Fish.fountain not found (run `swift test` from repo root)")
        let script = FNScript(file: url.path)
        let m = script.metrics
        XCTAssertGreaterThan(m.wordCountExcludingBoneyard, 2_000, "Feature-length dialogue/action volume")
        XCTAssertGreaterThan(m.dialogueWordCount, 500, "Substantial spoken text")

        let data = try script.fountainDocumentJSONData()
        let decoded = try JSONDecoder().decode(FountainDocument.self, from: data)
        ParseAssertions.assertFountainDocumentsStructurallyEqual(decoded, script.asFountainDocument())
    }
}
