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

    /// Scene numbers on slugs + page break between scenes (Phase 5.1 + 5.2 + 7.1).
    func testSceneNumbersWithPageBreakFixture() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "package-scene-pagebreak", withExtension: "fountain"))
        let text = try String(contentsOf: url, encoding: .utf8)
        let script = FNScript(string: text)
        let kinds = script.asFountainDocument().elements.map(\.kind)
        XCTAssertEqual(kinds, [.sceneHeading, .pageBreak, .sceneHeading, .action])
        let slugs = script.elements.filter { $0.elementType == "Scene Heading" }
        XCTAssertEqual(slugs.count, 2)
        XCTAssertEqual(slugs[0].sceneNumber, "1")
        XCTAssertEqual(slugs[1].sceneNumber, "2")
    }

    /// Boneyard between two action lines; body after `*/` must parse as action (Phase 5.3 + 7.1).
    func testBoneyardSandwichFixture() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "package-boneyard-sandwich", withExtension: "fountain"))
        let text = try String(contentsOf: url, encoding: .utf8)
        let script = FNScript(string: text)
        let kinds = script.asFountainDocument().elements.map(\.kind)
        XCTAssertEqual(kinds, [.sceneHeading, .action, .boneyard, .action])
        XCTAssertEqual(script.elements.last { $0.elementType == "Action" }?.elementText.contains("after"), true)
    }

    /// Section, synopsis, lyrics (multi-line), dialogue, bracket note, action — Phase 5 / 7.1 bundle.
    func testMixedProductionFixtureKindSequence() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "package-mixed-production", withExtension: "fountain"))
        let text = try String(contentsOf: url, encoding: .utf8)
        let script = FNScript(string: text)
        let kinds = script.asFountainDocument().elements.map(\.kind)
        XCTAssertEqual(
            kinds,
            [
                .sectionHeading, .synopsis, .sceneHeading,
                .lyrics, .lyrics,
                .character, .dialogue,
                .comment,
                .action,
            ]
        )
    }
}
