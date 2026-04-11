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

    /// ``FountainDocument`` / ``ScriptElementKind`` sequence (interchange model).
    static func assertScriptElementKinds(
        _ script: FNScript,
        _ expected: [ScriptElementKind],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let doc = script.asFountainDocument()
        XCTAssertEqual(doc.elements.count, expected.count, file: file, line: line)
        for i in 0 ..< expected.count {
            XCTAssertEqual(
                doc.elements[i].kind,
                expected[i],
                "index \(i)",
                file: file,
                line: line
            )
        }
    }

    static func assertMetadata(
        _ element: ScriptElement,
        key: FountainMetadataKey,
        value: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(element.metadata[key.rawValue], value, file: file, line: line)
    }

    /// Compares interchange shape ignoring ``ScriptElement/id`` (IDs differ across repeated ``asFountainDocument()`` calls).
    static func assertFountainDocumentsStructurallyEqual(
        _ a: FountainDocument,
        _ b: FountainDocument,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(a.titlePage, b.titlePage, file: file, line: line)
        XCTAssertEqual(a.fountainSyntaxVersion, b.fountainSyntaxVersion, file: file, line: line)
        XCTAssertEqual(a.elements.count, b.elements.count, file: file, line: line)
        for i in 0 ..< a.elements.count {
            XCTAssertEqual(a.elements[i].kind, b.elements[i].kind, "index \(i)", file: file, line: line)
            XCTAssertEqual(a.elements[i].text, b.elements[i].text, "index \(i)", file: file, line: line)
            XCTAssertEqual(a.elements[i].metadata, b.elements[i].metadata, "index \(i)", file: file, line: line)
        }
    }
}
