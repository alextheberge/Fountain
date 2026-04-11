import XCTest
import Fountain

/// Phase 7.1–7.2 — bundled fixture inventory plus minimal end-to-end ``FNScript`` rows
/// that complement ``SpecTraceabilityTests`` / ``PackageFixtureCorpusTests`` (official-style compliance matrix).
final class Phase7ComplianceTests: XCTestCase {
    /// Every `.fountain` processed under ``Tests/FountainPackageTests/Fixtures`` (update ``FountainPackageBundledFountainFixtures`` when adding files).
    func testBundledFixtureInventory() throws {
        for base in FountainPackageBundledFountainFixtures.basenames {
            let url = try XCTUnwrap(
                Bundle.module.url(forResource: base, withExtension: "fountain"),
                "Missing \(base).fountain — add under Fixtures/ and ensure Package.swift `.process(\"Fixtures\")`."
            )
            XCTAssertGreaterThan(try Data(contentsOf: url).count, 0, base)
        }
    }

    func testMinimalParentheticalDialogueSequence() {
        ParseAssertions.assertElementTypes(
            FNScript(string: "INT. X - DAY\n\nBOB\n(quiet)\nHi.\n"),
            [.sceneHeading, .character, .parenthetical, .dialogue]
        )
    }

    func testMinimalBracketNoteBetweenSlugAndAction() {
        ParseAssertions.assertElementTypes(
            FNScript(string: "INT. R - DAY\n\n[[ NOTE ]]\n\nAfter.\n"),
            [.sceneHeading, .comment, .action]
        )
    }

    func testMinimalPageBreakBetweenTwoSlugs() {
        ParseAssertions.assertElementTypes(
            FNScript(string: "INT. A - DAY\n\n===\n\nEXT. B - DAY\n"),
            [.sceneHeading, .pageBreak, .sceneHeading]
        )
    }

    /// Unforced transition between scenes (see ``FountainScriptMetricsTests`` transition count).
    func testMinimalUnforcedTransitionCutTo() {
        ParseAssertions.assertElementTypes(
            FNScript(string: "INT. FIRST - DAY\n\nLine.\n\nCUT TO:\n\nINT. SECOND - NIGHT\n\nMore.\n"),
            [.sceneHeading, .action, .transition, .sceneHeading, .action]
        )
    }

    /// ``FountainDocument`` JSON decode matches a fresh snapshot (ignores per-call element IDs).
    func testJSONExportStructuralParityIncludesParentheticalBlock() throws {
        let source = "INT. Q - DAY\n\nBOB\n(yes)\nGo.\n"
        let script = FNScript(string: source)
        let data = try script.fountainDocumentJSONData(prettyPrinted: false)
        let decoded = try JSONDecoder().decode(FountainDocument.self, from: data)
        ParseAssertions.assertFountainDocumentsStructurallyEqual(decoded, script.asFountainDocument())
    }
}
