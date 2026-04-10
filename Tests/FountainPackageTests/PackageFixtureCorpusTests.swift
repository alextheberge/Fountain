import XCTest
import Fountain

/// Phase 7.1 — curated `.fountain` files bundled with SPM tests (mirror of Xcode corpus patterns).
final class PackageFixtureCorpusTests: XCTestCase {
    func testRoundTripSampleFixtureParsesExpectedKinds() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "package-roundtrip-sample", withExtension: "fountain"))
        let text = try String(contentsOf: url, encoding: .utf8)
        let script = FNScript(string: text)
        let kinds = script.asFountainDocument().elements.map(\.kind)
        XCTAssertEqual(kinds, [.sceneHeading, .action, .character, .dialogue])
    }

    func testDualDialogueFixtureHasColumnMetadata() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "package-dual-dialogue", withExtension: "fountain"))
        let text = try String(contentsOf: url, encoding: .utf8)
        let script = FNScript(string: text)
        let chars = script.elements.filter { $0.elementType == FNElementType.character.rawValue }
        XCTAssertEqual(chars.count, 2)
        XCTAssertEqual(chars[0].dualDialogueColumn, 0)
        XCTAssertEqual(chars[1].dualDialogueColumn, 1)
    }

    func testForcedBlockFixtureParsesForcedElements() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "package-forced-block", withExtension: "fountain"))
        let text = try String(contentsOf: url, encoding: .utf8)
        let script = FNScript(string: text)
        let kinds = script.asFountainDocument().elements.map(\.kind)
        XCTAssertEqual(kinds, [.sceneHeading, .action, .character, .dialogue, .transition])
        XCTAssertTrue(script.elements.first { $0.elementType == "Action" }?.elementText.contains("!Forced") ?? false)
    }
}
