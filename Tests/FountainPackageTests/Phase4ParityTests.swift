import XCTest
import Fountain

/// Phase 4.5 — ``FountainScriptElementsBuilder`` element-type sequence matches default ``FNScript`` (**``.tokenPipeline``**) for representative and bundled sources (Phase **15.2**).
final class Phase4ParityTests: XCTestCase {
    private func assertElementTypesMatch(_ raw: String, file: StaticString = #filePath, line: UInt = #line) {
        let ref = FNScript(string: raw).elements.map(\.elementType)
        let built = FountainScriptElementsBuilder.buildElements(fromRawDocument: raw).map(\.elementType)
        XCTAssertEqual(built, ref, "Document:\n\(raw)", file: file, line: line)
    }

    func testParitySlugAction() {
        assertElementTypesMatch("\nINT. ROOM - DAY\n\nFirst.\nSecond.\n")
    }

    func testParityCharacterDialogue() {
        assertElementTypesMatch("\nINT. X\n\nBOB\nHi.\n")
    }

    func testParityParenthetical() {
        assertElementTypesMatch("\nINT. X\n\nBOB\n(beat)\nLine.\n")
    }

    func testParityScriptElementsBuilderMatchesDefaultParserAllBundledFountainFixtures() throws {
        for base in FountainPackageBundledFountainFixtures.basenames {
            let url = try XCTUnwrap(
                Bundle.module.url(forResource: base, withExtension: "fountain"),
                "Missing \(base).fountain",
                file: #filePath,
                line: #line
            )
            let raw = try String(contentsOf: url, encoding: .utf8)
            assertElementTypesMatch(raw, file: #filePath, line: #line)
        }
    }
}
