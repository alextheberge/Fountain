import XCTest
import Fountain

final class FountainScriptMetricsTests: XCTestCase {
    func testWordCountExcludesBoneyardText() {
        let script = FNScript(string: "\nINT. X - DAY\n\nHello world.\n\n/* ghost words */\n\nMORE\nLine.\n")
        let m = script.metrics
        let bodyBlob = script.elementsExcludingBoneyard.map(\.elementText).joined(separator: " ")
        XCTAssertFalse(bodyBlob.contains("ghost"))
        XCTAssertGreaterThan(m.wordCountExcludingBoneyard, 3)
        XCTAssertGreaterThan(m.dialogueWordCount, 0)
        XCTAssertLessThan(m.elementCountExcludingBoneyard, m.elementCount)
        XCTAssertEqual(m.sceneHeadingCount, 1)
        XCTAssertEqual(m.transitionCount, 0)
        XCTAssertEqual(m.characterCueCount, 1)
        XCTAssertEqual(m.dialogueElementCount, 1)
    }

    func testSceneAndTransitionCounts() {
        let script = FNScript(string: "\nINT. FIRST - DAY\n\nAction.\n\nCUT TO:\n\nINT. SECOND - NIGHT\n\nMore.\n")
        let m = script.metrics
        XCTAssertEqual(m.sceneHeadingCount, 2)
        XCTAssertEqual(m.transitionCount, 1)
    }

    func testCharacterAndDialogueElementCounts() {
        let script = FNScript(string: "\nINT. X - DAY\n\nALICE\nOne.\nTwo on same block.\n\nBOB\nHi.\n")
        let m = script.metrics
        XCTAssertEqual(m.characterCueCount, 2)
        XCTAssertEqual(m.dialogueElementCount, 2)
    }
}
