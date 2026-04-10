import XCTest
import Fountain

final class LineSplitterTests: XCTestCase {
    func testPreservesEmptyLines() {
        let lines = FountainLineSplitter.lines(from: "a\n\nb\n")
        XCTAssertEqual(lines, ["a", "", "b", ""])
    }

    func testNormalizesThenSplits() {
        let lines = FountainLineSplitter.lines(from: "x\r\ny")
        XCTAssertEqual(lines, ["x", "y"])
    }
}
