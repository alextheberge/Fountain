import XCTest
import Fountain

final class FountainLineToElementIndexMapTests: XCTestCase {
    func testSingleLineElementsMapOneLineEach() {
        let script = FNScript(string: "\nINT. X - DAY\n\nBOB\nHi.\n")
        let map = FountainLineToElementIndexMap(elements: script.elements)
        XCTAssertEqual(map.totalBodyLines, script.elements.count)
        for i in 0 ..< script.elements.count {
            XCTAssertEqual(map.elementIndex(forBodyLine: i), i)
        }
    }

    func testMultilineActionCountsLines() {
        let script = FNScript(string: "\nINT. X - DAY\n\nLine one.\nLine two.\n")
        let map = FountainLineToElementIndexMap(elements: script.elements)
        let actionIdx = script.elements.firstIndex { $0.elementType == "Action" }
        XCTAssertNotNil(actionIdx)
        let idx = actionIdx!
        let action = script.elements[idx]
        let expectedLines = 1 + action.elementText.filter { $0 == "\n" }.count
        XCTAssertGreaterThan(expectedLines, 1)
        var hits = 0
        for line in 0 ..< map.totalBodyLines where map.elementIndex(forBodyLine: line) == idx {
            hits += 1
        }
        XCTAssertEqual(hits, expectedLines)
    }
}
