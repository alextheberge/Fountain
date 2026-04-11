import XCTest
import Fountain

final class DialogueBlockRecognizerTests: XCTestCase {
    func testCharacterParentheticalDialogue() {
        let lines = ["BOB", "(beat)", "Hello there."]
        XCTAssertEqual(
            FountainDialogueBlockRecognizer.lineRoles(forNormalizedLines: lines),
            [.characterCue, .parenthetical, .dialogue]
        )
    }

    func testCharacterThenMultilineDialogue() {
        let lines = ["BOB", "First.", "Second."]
        XCTAssertEqual(
            FountainDialogueBlockRecognizer.lineRoles(forNormalizedLines: lines),
            [.characterCue, .dialogue, .dialogue]
        )
    }

    func testBlankResetsCharacter() {
        let lines = ["BOB", "Hi.", "", "ANN", "Yo."]
        XCTAssertEqual(
            FountainDialogueBlockRecognizer.lineRoles(forNormalizedLines: lines),
            [.characterCue, .dialogue, .blank, .characterCue, .dialogue]
        )
    }

    /// Matches ``FastFountainParser`` parenthetical rule: leading `(` after optional space, not “balanced on one line”.
    func testParentheticalDetectedWithLeadingParenOnly() {
        let lines = ["BOB", "  (not closed on same line", "Still parenthetical extension."]
        XCTAssertEqual(
            FountainDialogueBlockRecognizer.lineRoles(forNormalizedLines: lines),
            [.characterCue, .parenthetical, .dialogue]
        )
    }
}
