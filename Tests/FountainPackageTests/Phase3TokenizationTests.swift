import XCTest
import Fountain

/// Roadmap Phase 3 — title prescan, structural matchers, and coarse body line tokenizer.
final class Phase3TokenizationTests: XCTestCase {
    func testTitlePagePrescanMatchesFNScript() {
        let raw = "Title: The Film\nCredit: A Writer\n\nFirst line of action.\n"
        let prepared = FountainTitlePagePrescan.normalizeLikeFastParser(raw)
        let (tp, _) = FountainTitlePagePrescan.extractTitlePage(fromPreparedContents: prepared)
        let script = FNScript(string: raw)
        XCTAssertEqual(tp.count, script.titlePage.count)
        let keys = Set(tp.compactMap { $0.keys.first })
        XCTAssertTrue(keys.contains("title"))
        XCTAssertTrue(keys.contains("credit"))
    }

    func testTitlePagePrescanLeavesLoneFadeInInBody() {
        let raw = "FADE IN:\n\nINT. ROOM - DAY\n\nAction.\n"
        let prepared = FountainTitlePagePrescan.normalizeLikeFastParser(raw)
        let (tp, remainder) = FountainTitlePagePrescan.extractTitlePage(fromPreparedContents: prepared)
        XCTAssertTrue(tp.isEmpty, "Prescan must not treat lone FADE IN: as title page")
        XCTAssertTrue(remainder.contains("INT. ROOM"), "Slug stays in remainder")
    }

    func testShouldParseStructuredTitlePageFalseForLoneDirective() {
        let top = "FADE IN:"
        XCTAssertFalse(FountainTitlePagePrescan.shouldParseStructuredTitlePage(topOfDocument: top))
        XCTAssertTrue(FountainTitlePagePrescan.shouldParseStructuredTitlePage(topOfDocument: "Title: X\nAuthor: Y"))
    }

    func testStructuralMatchers() {
        XCTAssertTrue(FountainStructuralLineMatchers.isPageBreakLine("==="))
        XCTAssertTrue(FountainStructuralLineMatchers.isPageBreakLine("==== \t"))
        XCTAssertFalse(FountainStructuralLineMatchers.isPageBreakLine("= synopsis"))
        XCTAssertTrue(FountainStructuralLineMatchers.isSynopsisLine(trimmedLine: "= beat"))
        XCTAssertTrue(FountainStructuralLineMatchers.isSectionHeadingLine(trimmedLine: "## Act"))
        XCTAssertTrue(FountainStructuralLineMatchers.isBoneyardOpenLine("/* note"))
        XCTAssertTrue(FountainStructuralLineMatchers.isSingleLineBoneyard("/* x */"))
    }

    func testBodyLineTokenizerSlugActionForcedBang() {
        let raw = "INT. ROOM - DAY\n\nHello.\n\n!Forced\nMore.\n"
        let (_, tokens) = FountainBodyLineTokenizer.tokenizeBodyAfterTitlePrescan(rawDocument: raw)
        let kinds = tokens.filter { $0.kind != .blank }.map(\.kind)
        XCTAssertEqual(
            kinds,
            [.sceneHeading, .action, .forcedAction, .action],
            "Kinds: \(kinds)"
        )
    }

    func testTokenizerCharacterDialogueParenthetical() {
        let raw = "INT. X\n\nBOB\n(quiet)\nHi.\n"
        let (_, tokens) = FountainBodyLineTokenizer.tokenizeBodyAfterTitlePrescan(rawDocument: raw)
        let kinds = tokens.filter { $0.kind != .blank }.map(\.kind)
        XCTAssertEqual(kinds, [.sceneHeading, .characterCue, .parenthetical, .dialogue])
    }

    func testTokenizerCenteredAndTransitionWithForcedPrefix() {
        let raw = "> look <\n\n> CUT TO:\n"
        let (_, tokens) = FountainBodyLineTokenizer.tokenizeBodyAfterTitlePrescan(rawDocument: raw)
        let kinds = tokens.filter { $0.kind != .blank }.map(\.kind)
        // `> CUT TO:` matches the same `…TO:` transition rule as an unforced transition (before the bare-`>` branch).
        XCTAssertEqual(kinds, [.centeredText, .transition])
    }

    func testTokenizerMatchesFNScriptElementKindSequenceForSample() {
        let raw = "INT. ROOM - DAY\n\nPlain action.\n"
        let script = FNScript(string: raw)
        let (_, tokens) = FountainBodyLineTokenizer.tokenizeBodyAfterTitlePrescan(rawDocument: raw)
        let tokenKinds = tokens.filter { $0.kind != .blank }.map(\.kind)
        let elementKinds = script.elements.compactMap { el -> FountainTokenKind? in
            switch el.elementType {
            case "Scene Heading": return .sceneHeading
            case "Action": return .action
            default: return nil
            }
        }
        XCTAssertEqual(tokenKinds, elementKinds)
    }
}
