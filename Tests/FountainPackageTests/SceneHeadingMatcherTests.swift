import XCTest
import Fountain

/// Phase 3.5 / 11 — ``FountainSceneHeadingMatcher`` matches standard sluglines (Swift `Regex`, case-insensitive).
final class SceneHeadingMatcherTests: XCTestCase {
    func testStandardSlugs() {
        XCTAssertTrue(FountainSceneHeadingMatcher.matchesStandardSlugLine("INT. HOUSE - DAY"))
        XCTAssertTrue(FountainSceneHeadingMatcher.matchesStandardSlugLine("EXT. BEACH - NIGHT"))
        XCTAssertTrue(FountainSceneHeadingMatcher.matchesStandardSlugLine("INT./EXT. SOMEWHERE - LATER"))
        XCTAssertFalse(FountainSceneHeadingMatcher.matchesStandardSlugLine("FADE IN:"))
        XCTAssertFalse(FountainSceneHeadingMatcher.matchesStandardSlugLine(". FORCED SLUG"))
    }

    func testStandardSlugsAreCaseInsensitive() {
        XCTAssertTrue(FountainSceneHeadingMatcher.matchesStandardSlugLine("int. kitchen - day"))
        XCTAssertTrue(FountainSceneHeadingMatcher.matchesStandardSlugLine("  ext. PIER - night  "))
    }
}
