import XCTest
import Fountain

final class ForcedPrefixScannerTests: XCTestCase {
    func testMapsForcedPrefixesToTokenKinds() {
        XCTAssertEqual(FountainForcedPrefixScanner.forcedTokenKind(forLine: "! boom"), .forcedAction)
        XCTAssertEqual(FountainForcedPrefixScanner.forcedTokenKind(forLine: "  @X"), .forcedCharacterCue)
        XCTAssertEqual(FountainForcedPrefixScanner.forcedTokenKind(forLine: "~song"), .lyrics)
        XCTAssertEqual(FountainForcedPrefixScanner.forcedTokenKind(forLine: ". SLUG HERE"), .forcedSceneHeading)
        XCTAssertEqual(FountainForcedPrefixScanner.forcedTokenKind(forLine: "> TO: KITCHEN"), .forcedTransition)
        XCTAssertEqual(FountainForcedPrefixScanner.forcedTokenKind(forLine: "> x <"), .centeredText)
    }

    func testIgnoresNonForcedLines() {
        XCTAssertNil(FountainForcedPrefixScanner.forcedTokenKind(forLine: "INT. X - DAY"))
        XCTAssertNil(FountainForcedPrefixScanner.forcedTokenKind(forLine: "..not a slug"))
        XCTAssertNil(FountainForcedPrefixScanner.forcedTokenKind(forLine: ""))
        XCTAssertNil(FountainForcedPrefixScanner.forcedTokenKind(forLine: "   "))
    }
}
