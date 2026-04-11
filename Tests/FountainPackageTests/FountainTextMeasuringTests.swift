import XCTest
import Fountain

/// Phase 8.5 — ``CourierPitchMonospaceTextMeasurer`` contract (used for future ``FNPaginator`` injection).
final class FountainTextMeasuringTests: XCTestCase {
    func testCourierPitchMeasurerReturnsPositiveHeight() {
        let m = CourierPitchMonospaceTextMeasurer()
        XCTAssertEqual(m.layoutLineHeight, 12)
        let h = m.heightForString("Hello", maxWidth: 430)
        XCTAssertGreaterThan(h, 0)
    }

    func testMultilineStringIncreasesHeight() {
        let m = CourierPitchMonospaceTextMeasurer()
        let one = m.heightForString("word", maxWidth: 100)
        let two = m.heightForString("word\nword", maxWidth: 100)
        XCTAssertGreaterThanOrEqual(two, one)
    }

    /// Phase 8.5 follow-up — ``FNPaginator`` uses injected measurement via closure (no stored `any`).
    func testPaginatorUsesCourierPitchMeasurerWithoutCrash() {
        let script = FNScript(string: "\nINT. STUDIO - DAY\n\nLine before break.\n\n===\n\nLine after break.\n")
        let paginator = FNPaginator(script: script, textMeasurer: CourierPitchMonospaceTextMeasurer())
        XCTAssertGreaterThanOrEqual(paginator.numberOfPages, 1)
        XCTAssertTrue((0 ..< paginator.numberOfPages).contains { i in
            paginator.pageAtIndex(i).contains { $0.elementType == "Page Break" }
        })
    }
}
