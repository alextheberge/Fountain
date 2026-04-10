import XCTest
import Fountain

/// Maps spec traceability rows to minimal SPM coverage (Phases 3–4 + title page).
final class SpecTraceabilityTests: XCTestCase {
    func testForcedSceneHeadingDot() {
        ParseAssertions.assertElementTypes(
            FNScript(string: "\n. FORCED SLUG HERE\n\nAction.\n"),
            [.sceneHeading, .action]
        )
    }

    func testForcedActionBang() {
        ParseAssertions.assertElementTypes(
            FNScript(string: "\n! Forced action\n"),
            [.action]
        )
    }

    func testForcedCharacterAt() {
        ParseAssertions.assertElementTypes(
            FNScript(string: "\n@SOMEONE\nThey speak.\n"),
            [.character, .dialogue]
        )
    }

    func testForcedTransitionGreaterThan() {
        ParseAssertions.assertElementTypes(
            FNScript(string: "\n> WIPE TO:\n"),
            [.transition]
        )
    }

    func testLyricsTilde() {
        ParseAssertions.assertElementTypes(
            FNScript(string: "\n~♪ Singing\n"),
            [.lyrics]
        )
    }

    func testCenteredAction() {
        ParseAssertions.assertElementTypes(
            FNScript(string: "\n> centered <\n"),
            [.action]
        )
        XCTAssertTrue(FNScript(string: "\n> centered <\n").elements[0].isCentered)
    }

    func testDualDialogueCaretAndCodableMetadata() {
        let script = FNScript(string: "\nADAM\nYes.\n\nEVE ^\nNo.\n")
        let chars = script.elements.filter { $0.elementType == FNElementType.character.rawValue }
        XCTAssertEqual(chars.count, 2)
        XCTAssertTrue(chars[0].isDualDialogue)
        XCTAssertTrue(chars[1].isDualDialogue)
        XCTAssertEqual(chars[0].dualDialogueColumn, 0)
        XCTAssertEqual(chars[1].dualDialogueColumn, 1)
        let doc = FountainDocument(script: script)
        let dualFlags = doc.elements.filter { $0.kind == .character }.map {
            $0.metadata[FountainMetadataKey.dualDialogue.rawValue] == "true"
        }
        XCTAssertEqual(dualFlags, [true, true])
        let columns = doc.elements.filter { $0.kind == .character }.map {
            $0.metadata[FountainMetadataKey.dualDialogueColumn.rawValue]
        }
        XCTAssertEqual(columns, ["0", "1"])
    }

    func testTitlePageKeyValueSmoke() {
        let script = FNScript(string: "Title: Trace Test\n\nINT. ROOM - DAY\n")
        XCTAssertFalse(script.titlePage.isEmpty)
        let keys = Set(script.titlePage.compactMap(\.keys.first))
        XCTAssertTrue(keys.contains("title"))
    }
}
