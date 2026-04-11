import XCTest
import Fountain

/// Roadmap Phase 2.3 — `FountainDocument` reflects `FastFountainParser` / `FNElement` labels for a corpus subset.
final class LegacyInteropTests: XCTestCase {
    func testDocumentKindsMatchParserForSamples() {
        let cases: [(String, [FNElementType])] = [
            ("INT. ROOM - DAY\n\nPlain action.\n", [.sceneHeading, .action]),
            (". FORCED SLUG\n\nMore action.\n", [.sceneHeading, .action]),
            ("! Forced action line\n", [.action]),
            ("@FORCED CHARACTER\nWhat they say.\n", [.character, .dialogue]),
            ("~Singing here\n", [.lyrics]),
            ("> CUT TO:\n", [.transition]),
            ("> centered line <\n", [.action]),
        ]
        for (source, types) in cases {
            let script = FNScript(string: source)
            let doc = script.asFountainDocument()
            XCTAssertEqual(
                doc.elements.count,
                types.count,
                "Element count mismatch for: \(source.prefix(40))…"
            )
            for i in 0 ..< types.count {
                XCTAssertEqual(
                    doc.elements[i].kind,
                    types[i].scriptElementKind,
                    "Index \(i) for: \(source.prefix(40))…"
                )
            }
        }
    }

    func testCenteredForcedLineCarriesMetadata() {
        let script = FNScript(string: "> look <\n")
        let doc = script.asFountainDocument()
        XCTAssertEqual(doc.elements.count, 1)
        XCTAssertEqual(doc.elements[0].kind, .action)
        XCTAssertEqual(doc.elements[0].metadata[FountainMetadataKey.centered.rawValue], "true")
    }

    func testFNElementJSONRoundTripPreservesId() throws {
        let original = FNElement.element(ofType: "Action", text: "Line")
        let data = try JSONEncoder().encode([original])
        let decoded = try JSONDecoder().decode([FNElement].self, from: data)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].id, original.id)
        XCTAssertEqual(decoded[0].elementType, "Action")
        XCTAssertEqual(decoded[0].elementText, "Line")
    }

    func testFountainDocumentScriptElementIdsMatchParsedElements() {
        let script = FNScript(string: "INT. ROOM - DAY\n\nPlain action.\n")
        let doc = script.asFountainDocument()
        XCTAssertEqual(doc.elements.count, script.elements.count)
        for i in script.elements.indices {
            XCTAssertEqual(script.elements[i].id, doc.elements[i].id, "row \(i)")
        }
    }
}
