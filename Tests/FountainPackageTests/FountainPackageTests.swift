import XCTest
import Fountain

final class FountainPackageTests: XCTestCase {
    func testCodableRoundTrip() throws {
        let script = FNScript(string: "INT. ROOM - DAY\n\nSome action.\n")
        let doc = script.asFountainDocument()
        let data = try JSONEncoder().encode(doc)
        let decoded = try JSONDecoder().decode(FountainDocument.self, from: data)
        XCTAssertEqual(decoded.fountainSyntaxVersion, "1.1")
        XCTAssertFalse(decoded.elements.isEmpty)
        XCTAssertTrue(decoded.elements.contains { $0.kind == .sceneHeading })
        XCTAssertTrue(decoded.elements.contains { $0.kind == .action })
    }

    func testUmbrellaExportsHTML() {
        let script = FNScript(string: "Title\n\n===\n\nScene one.\n")
        let html = FNHTMLScript(script: script)
        XCTAssertFalse(html.html().isEmpty)
    }
}
