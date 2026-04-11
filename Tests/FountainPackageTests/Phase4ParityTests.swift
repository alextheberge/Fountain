import XCTest
import Fountain

/// Phase 4.5 — token stream assembly matches ``FNScript`` / ``FastFountainParser`` for representative sources.
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

    func testParityBoneyardSandwich() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "package-boneyard-sandwich", withExtension: "fountain"))
        let raw = try String(contentsOf: url, encoding: .utf8)
        assertElementTypesMatch(raw)
    }

    func testParityDualDialogueFixture() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "package-dual-dialogue", withExtension: "fountain"))
        let raw = try String(contentsOf: url, encoding: .utf8)
        assertElementTypesMatch(raw)
    }

    func testParityMixedProductionFixture() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "package-mixed-production", withExtension: "fountain"))
        let raw = try String(contentsOf: url, encoding: .utf8)
        assertElementTypesMatch(raw)
    }

    func testParityForcedBlockFixture() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "package-forced-block", withExtension: "fountain"))
        let raw = try String(contentsOf: url, encoding: .utf8)
        assertElementTypesMatch(raw)
    }
}
