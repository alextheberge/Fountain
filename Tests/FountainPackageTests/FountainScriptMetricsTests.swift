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
    }
}
