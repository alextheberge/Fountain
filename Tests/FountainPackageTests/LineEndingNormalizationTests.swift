import XCTest
import Fountain

final class LineEndingNormalizationTests: XCTestCase {
    func testMixedLineEndingsBecomeLF() {
        let raw = "line1\r\nline2\rline3\nline4"
        let out = FountainLineEndingNormalizer.normalize(raw)
        XCTAssertFalse(out.contains("\r"))
        XCTAssertEqual(out.split(separator: "\n", omittingEmptySubsequences: false).count, 4)
    }

    func testTokenKindVocabularyIsStable() {
        XCTAssertTrue(FountainTokenKind.allCases.contains(.sceneHeading))
        XCTAssertTrue(FountainTokenKind.allCases.contains(.titlePageDirective))
        XCTAssertGreaterThanOrEqual(FountainTokenKind.allCases.count, 20)
    }
}
