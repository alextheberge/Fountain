import XCTest
import Fountain

/// ``FNParserType/tokenPipeline`` must stay aligned with production ``fast`` for parity-tracked sources.
final class TokenPipelineFNScriptTests: XCTestCase {
    private func assertFastAndTokenPipelineMatch(
        _ raw: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let fast = FNScript(string: raw, parser: .fast)
        let token = FNScript(string: raw, parser: .tokenPipeline)
        XCTAssertEqual(
            token.elements.map(\.elementType),
            fast.elements.map(\.elementType),
            "elementType sequence",
            file: file,
            line: line
        )
        XCTAssertEqual(
            token.elements.map(\.elementText),
            fast.elements.map(\.elementText),
            "elementText sequence",
            file: file,
            line: line
        )
        XCTAssertEqual(
            FountainWriter.titlePageFromScript(token).trimmingCharacters(in: .whitespacesAndNewlines),
            FountainWriter.titlePageFromScript(fast).trimmingCharacters(in: .whitespacesAndNewlines),
            "title page Fountain export parity",
            file: file,
            line: line
        )
    }

    func testTokenPipelineMatchesFastSlugAction() {
        assertFastAndTokenPipelineMatch("\nINT. ROOM - DAY\n\nFirst.\nSecond.\n")
    }

    func testTokenPipelineMatchesFastCharacterDialogue() {
        assertFastAndTokenPipelineMatch("\nINT. X\n\nBOB\nHi.\n")
    }

    func testTokenPipelineMatchesFastTitlePageAndBody() {
        assertFastAndTokenPipelineMatch("Title: Parity Check\nCredit: Writer\n\nINT. T - DAY\n\nAction.\n")
    }

    func testTokenPipelineFixtureParityBoneyardSandwich() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "package-boneyard-sandwich", withExtension: "fountain"))
        let raw = try String(contentsOf: url, encoding: .utf8)
        assertFastAndTokenPipelineMatch(raw)
    }

    func testTokenPipelineFixtureParityDualDialogue() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "package-dual-dialogue", withExtension: "fountain"))
        let raw = try String(contentsOf: url, encoding: .utf8)
        assertFastAndTokenPipelineMatch(raw)
    }

    func testFountainParsePipelineMatchesBuilderHelper() {
        let raw = "\nINT. API - DAY\n\nLine.\n"
        let viaPipeline = FountainParsePipeline.parseDocument(string: raw)
        let viaBuilder = FountainScriptElementsBuilder.buildElements(fromRawDocument: raw)
        XCTAssertEqual(viaPipeline.elements.map(\.elementType), viaBuilder.map(\.elementType))
        XCTAssertEqual(viaPipeline.elements.map(\.elementText), viaBuilder.map(\.elementText))
    }
}
