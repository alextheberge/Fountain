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

    /// ``FastFountainParser`` merges a slug with the following line when there is **no** blank between them (slug becomes action).
    func testTokenPipelineMatchesFastSlugWithImmediateActionNoBlank() {
        assertFastAndTokenPipelineMatch(
            """

            INT. MERGED - DAY
            Opening description on the next line with no blank after the slug.

            BOB
            Hi.
            """
        )
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

    /// Every bundled `.fountain` under `Fixtures/` must keep **fast** vs **tokenPipeline** parity (see ``FountainPackageBundledFountainFixtures``).
    func testTokenPipelineParityAllBundledFountainFixtures() throws {
        for base in FountainPackageBundledFountainFixtures.basenames {
            let url = try XCTUnwrap(
                Bundle.module.url(forResource: base, withExtension: "fountain"),
                "Missing fixture \(base).fountain"
            )
            let raw = try String(contentsOf: url, encoding: .utf8)
            assertFastAndTokenPipelineMatch(raw, file: #filePath, line: #line)
        }
    }

    /// Feature-length **fast** vs **tokenPipeline** parity (continuation merge, slug + action, etc.).
    func testTokenPipelineBigFishFileMatchesFast() throws {
        let url = try XCTUnwrap(bigFishFountainURL(), "Big Fish.fountain not found (run swift test from repo root)")
        let fast = FNScript(file: url.path, parser: .fast)
        let token = FNScript(file: url.path, parser: .tokenPipeline)
        XCTAssertEqual(token.elements.count, fast.elements.count, "Big Fish element count")
        XCTAssertEqual(token.elements.map(\.elementType), fast.elements.map(\.elementType), "Big Fish element types")
        XCTAssertEqual(token.elements.map(\.elementText), fast.elements.map(\.elementText), "Big Fish element texts")
        XCTAssertEqual(
            FountainWriter.titlePageFromScript(token).trimmingCharacters(in: .whitespacesAndNewlines),
            FountainWriter.titlePageFromScript(fast).trimmingCharacters(in: .whitespacesAndNewlines),
            "Big Fish title page export parity"
        )
    }

    func testTokenPipelineBrickAndSteelFileMatchesFast() throws {
        let url = try XCTUnwrap(brickSteelFountainURL(), "Brick And Steel.txt not found (run swift test from repo root)")
        let fast = FNScript(file: url.path, parser: .fast)
        let token = FNScript(file: url.path, parser: .tokenPipeline)
        XCTAssertEqual(token.elements.count, fast.elements.count, "Brick & Steel element count")
        XCTAssertEqual(token.elements.map(\.elementType), fast.elements.map(\.elementType), "Brick & Steel element types")
        XCTAssertEqual(token.elements.map(\.elementText), fast.elements.map(\.elementText), "Brick & Steel element texts")
        XCTAssertEqual(
            FountainWriter.titlePageFromScript(token).trimmingCharacters(in: .whitespacesAndNewlines),
            FountainWriter.titlePageFromScript(fast).trimmingCharacters(in: .whitespacesAndNewlines),
            "Brick & Steel title page export parity"
        )
    }

    private func brickSteelFountainURL() -> URL? {
        var fromFile = URL(fileURLWithPath: "\(#filePath)")
        for _ in 0 ..< 3 {
            fromFile.deleteLastPathComponent()
        }
        let fromFileCandidate = fromFile.appendingPathComponent("FountainTests/Resources/Brick And Steel.txt")
        let cwdCandidate = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("FountainTests/Resources/Brick And Steel.txt")
        if FileManager.default.fileExists(atPath: fromFileCandidate.path) { return fromFileCandidate }
        if FileManager.default.fileExists(atPath: cwdCandidate.path) { return cwdCandidate }
        return nil
    }

    private func bigFishFountainURL() -> URL? {
        var fromFile = URL(fileURLWithPath: "\(#filePath)")
        for _ in 0 ..< 3 {
            fromFile.deleteLastPathComponent()
        }
        let fromFileCandidate = fromFile.appendingPathComponent("FountainTests/Resources/Big Fish.fountain")
        let cwdCandidate = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("FountainTests/Resources/Big Fish.fountain")
        if FileManager.default.fileExists(atPath: fromFileCandidate.path) { return fromFileCandidate }
        if FileManager.default.fileExists(atPath: cwdCandidate.path) { return cwdCandidate }
        return nil
    }
}
