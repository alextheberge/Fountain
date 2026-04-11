import XCTest
import Fountain

/// Roadmap Phase 4.6 — whitespace-only lines are not standalone **Action**; use `!` for forced action.
final class Phase46WhitespaceActionTests: XCTestCase {
    func testWhitespaceOnlyLineOutsideDialogueDoesNotEmitActionElement() {
        let script = FNScript(string: """
        INT. ROOM - DAY

           \t
        Real action line.
        """)
        XCTAssertFalse(script.elements.contains { $0.elementType == "Action" && $0.elementText.range(of: #"^\s+$"#, options: .regularExpression) != nil })
        XCTAssertTrue(script.elements.contains { $0.elementType == "Action" && $0.elementText.contains("Real action line.") })
    }

    func testTokenPipelineMatchesFastForWhitespaceOnlyLine() {
        let raw = "\nINT. ROOM - DAY\n\n   \nNext line.\n"
        let fast = FNScript(string: raw, parser: .fast)
        let pipe = FNScript(string: raw, parser: .tokenPipeline)
        XCTAssertEqual(fast.elements.map(\.elementType), pipe.elements.map(\.elementType))
    }
}
