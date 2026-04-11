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

    /// Every bundled `.fountain` under `Fixtures/` must keep **fast** vs **tokenPipeline** parity.
    func testTokenPipelineParityAllBundledFountainFixtures() throws {
        let names = [
            "package-boneyard-sandwich",
            "package-dual-dialogue",
            "package-forced-block",
            "package-mixed-production",
            "package-roundtrip-sample",
            "package-scene-pagebreak",
            "export-golden-minimal",
        ]
        for base in names {
            let url = try XCTUnwrap(
                Bundle.module.url(forResource: base, withExtension: "fountain"),
                "Missing fixture \(base).fountain"
            )
            let raw = try String(contentsOf: url, encoding: .utf8)
            assertFastAndTokenPipelineMatch(raw, file: #filePath, line: #line)
        }
    }

    /// Full-script **fast** vs **tokenPipeline** element sequences still diverge on Big Fish (merging / boundary heuristics).
    /// Keep a **scale** check so the tokenizer path survives feature-length input; tighten to full parity when the pipeline catches up.
    func testBigFishTokenPipelineParsesWithManyElements() throws {
        let url = try XCTUnwrap(bigFishFountainURL(), "Big Fish.fountain not found (run swift test from repo root)")
        let script = FNScript(file: url.path, parser: .tokenPipeline)
        XCTAssertGreaterThan(script.elements.count, 500, "Sanity: Big Fish on tokenPipeline should yield hundreds of elements")
    }

    private func bigFishFountainURL() -> URL? {
        var fromFile = URL(fileURLWithPath: "\(#filePath)")
        for _ in 0 ..< 3 {
            fromFile.deleteLastPathComponent()
        }
        let fromFileCandidate = fromFile.appendingPathComponent("FountainTests/Big Fish.fountain")
        let cwdCandidate = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("FountainTests/Big Fish.fountain")
        if FileManager.default.fileExists(atPath: fromFileCandidate.path) { return fromFileCandidate }
        if FileManager.default.fileExists(atPath: cwdCandidate.path) { return cwdCandidate }
        return nil
    }
}
