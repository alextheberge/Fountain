import XCTest
import Fountain

/// Phase 7.2 — structured expectations on parsed element type strings (not HTML snapshots).
enum ParseAssertions {
    static func assertElementTypes(
        _ script: FNScript,
        _ expected: [FNElementType],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(script.elements.count, expected.count, file: file, line: line)
        for i in 0 ..< expected.count {
            XCTAssertEqual(
                script.elements[i].elementType,
                expected[i].rawValue,
                "index \(i)",
                file: file,
                line: line
            )
        }
    }
}
