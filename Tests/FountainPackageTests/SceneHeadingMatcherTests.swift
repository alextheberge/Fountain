import XCTest
import Fountain

final class SceneHeadingMatcherTests: XCTestCase {
    func testStandardSlugs() {
        XCTAssertTrue(FountainSceneHeadingMatcher.matchesStandardSlugLine("INT. HOUSE - DAY"))
        XCTAssertTrue(FountainSceneHeadingMatcher.matchesStandardSlugLine("EXT. BEACH - NIGHT"))
        XCTAssertTrue(FountainSceneHeadingMatcher.matchesStandardSlugLine("INT./EXT. SOMEWHERE - LATER"))
        XCTAssertFalse(FountainSceneHeadingMatcher.matchesStandardSlugLine("FADE IN:"))
        XCTAssertFalse(FountainSceneHeadingMatcher.matchesStandardSlugLine(". FORCED SLUG"))
    }
}
