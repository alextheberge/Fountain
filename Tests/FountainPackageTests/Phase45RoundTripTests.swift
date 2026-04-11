import XCTest
import Fountain

/// Phase 4.5 — canonical ``FountainDocument`` / export round-trip smoke (structure stable for tooling).
final class Phase45RoundTripTests: XCTestCase {
    func testFountainDocumentJSONRoundTripPreservesStructure() throws {
        let script = FNScript(string: "\nINT. JSON - DAY\n\nHello.\n")
        let original = script.asFountainDocument()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FountainDocument.self, from: data)
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.elements.map(\.kind), [.sceneHeading, .action])
    }

    /// Public export path (Phase 2.4 / 8.3): decode must match a fresh document snapshot (structurally; IDs are per-snapshot).
    func testFountainDocumentJSONDataAPIRoundTrip() throws {
        let script = FNScript(string: "\n# ACT I\n= Beat.\n\nINT. API - DAY\n\nBOB\nLine.\n")
        let data = try script.fountainDocumentJSONData(prettyPrinted: true)
        let decoded = try JSONDecoder().decode(FountainDocument.self, from: data)
        ParseAssertions.assertFountainDocumentsStructurallyEqual(decoded, script.asFountainDocument())
        let dataBare = try script.fountainDocumentJSONData(prettyPrinted: false)
        let decodedBare = try JSONDecoder().decode(FountainDocument.self, from: dataBare)
        ParseAssertions.assertFountainDocumentsStructurallyEqual(decodedBare, script.asFountainDocument())
    }

    func testPlaintextWriterRoundTripPreservesElementKindSequence() {
        let source = "\nINT. PLAIN - DAY\n\nAction line.\n\nBOB\nHi there.\n"
        let first = FNScript(string: source)
        let roundTrip = FountainWriter.documentFromScript(first)
        let second = FNScript(string: roundTrip)
        XCTAssertEqual(
            first.elements.map(\.elementType),
            second.elements.map(\.elementType),
            "Kind sequence should survive Fountain plain export and re-parse"
        )
    }
}
