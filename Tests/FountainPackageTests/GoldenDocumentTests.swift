import XCTest
import Fountain

final class GoldenDocumentTests: XCTestCase {
    func testDecodeGoldenFixture() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "simple-document", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let doc = try JSONDecoder().decode(FountainDocument.self, from: data)
        XCTAssertEqual(doc.fountainSyntaxVersion, "1.1")
        XCTAssertEqual(doc.elements.count, 2)
        XCTAssertEqual(doc.elements[0].kind, .sceneHeading)
        XCTAssertEqual(doc.elements[0].text, "INT. ROOM - DAY")
        XCTAssertEqual(doc.elements[1].kind, .action)
        XCTAssertEqual(doc.elements[1].text, "She enters.")
    }

    func testGoldenFixtureRoundTripEncode() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "simple-document", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let doc = try JSONDecoder().decode(FountainDocument.self, from: data)
        let encoded = try JSONEncoder().encode(doc)
        let again = try JSONDecoder().decode(FountainDocument.self, from: encoded)
        XCTAssertEqual(again, doc)
    }

    func testParseProducesSameShapeAsGoldenFixture() {
        let script = FNScript(string: "INT. ROOM - DAY\n\nShe enters.\n")
        let doc = script.asFountainDocument()
        XCTAssertEqual(doc.elements.map(\.kind), [.sceneHeading, .action])
        XCTAssertEqual(doc.elements.map(\.text), ["INT. ROOM - DAY", "She enters."])
    }

    func testFNElementTypeCoversFastParserLabels() {
        XCTAssertEqual(FNElementType.sceneHeading.scriptElementKind, .sceneHeading)
        XCTAssertEqual(FNElementType.comment.scriptElementKind, .comment)
        XCTAssertEqual(ScriptElementKind(legacyType: "Scene Heading"), .sceneHeading)
        XCTAssertEqual(ScriptElementKind(legacyType: "Not A Real Type"), .unknown)
    }
}
