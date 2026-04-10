import XCTest
import Fountain

/// Phase 4.3 — action continuation without blank lines; prefer `!` over legacy “trailing space” forcing (see roadmap note).
final class ActionMergingTests: XCTestCase {
    func testConsecutiveActionLinesMergeIntoSingleElement() {
        let script = FNScript(string: """
        INT. ROOM - DAY

        First beat.
        Second beat on the next line.
        """)

        let actions = script.elements.filter { $0.elementType == "Action" }
        XCTAssertEqual(actions.count, 1)
        XCTAssertTrue(actions[0].elementText.contains("First beat."))
        XCTAssertTrue(actions[0].elementText.contains("Second beat"))
        XCTAssertTrue(actions[0].elementText.contains("\n"))
    }

    func testForcedActionContinuationMergesWithFollowingLine() {
        let script = FNScript(string: """
        INT. ROOM - DAY

        !FORCED ACTION LINE
        Still the same paragraph per Fountain 1.1 soft break rules.
        """)

        let actions = script.elements.filter { $0.elementType == "Action" }
        XCTAssertEqual(actions.count, 1)
        XCTAssertTrue(actions[0].elementText.hasPrefix("!FORCED ACTION"))
        XCTAssertTrue(actions[0].elementText.contains("Still the same"))
    }
}
