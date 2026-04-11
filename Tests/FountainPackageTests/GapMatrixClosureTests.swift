import XCTest
import Fountain

/// Closes remaining **P** rows in [Fountain-1.1-Gap-Analysis.md](../../docs/Fountain-1.1-Gap-Analysis.md) feature matrix (dual `^`, forced `>`, synopsis `=`, boneyard, scene `#…#`, inline BIU).
final class GapMatrixClosureTests: XCTestCase {
    // MARK: - Dual dialogue `^`

    func testDualDialogueColumnsAndDocumentMetadata() {
        let script = FNScript(string: "\nADAM\nYes.\n\nEVE ^\nNo.\n")
        let chars = script.elements.filter { $0.elementType == FNElementType.character.rawValue }
        XCTAssertEqual(chars.count, 2)
        XCTAssertTrue(chars[0].isDualDialogue && chars[1].isDualDialogue)
        XCTAssertEqual(chars[0].dualDialogueColumn, 0)
        XCTAssertEqual(chars[1].dualDialogueColumn, 1)
        let doc = script.asFountainDocument()
        let docChars = doc.elements.filter { $0.kind == .character }
        XCTAssertEqual(docChars.map { $0.metadata[FountainMetadataKey.dualDialogueColumn.rawValue] }, ["0", "1"])
    }

    func testDualDialogueCaretAllowsTrailingWhitespace() {
        let script = FNScript(string: "\nLEFT\nL.\n\nRIGHT ^  \nR.\n")
        let right = script.elements.last { $0.elementType == "Character" }
        XCTAssertTrue(right?.isDualDialogue == true)
        XCTAssertEqual(right?.dualDialogueColumn, 1)
        XCTAssertFalse(right?.elementText.contains("^") ?? true)
    }

    // MARK: - Forced transition `>` vs centered `> … <`

    func testForcedTransitionGreaterThanWithoutClosingAngle() {
        ParseAssertions.assertElementTypes(
            FNScript(string: "\nINT. X - DAY\n\n> WIPE TO:\n"),
            [.sceneHeading, .transition]
        )
    }

    func testForcedTransitionGreaterThanBareForcedLine() {
        ParseAssertions.assertElementTypes(
            FNScript(string: "\n> OMITTED SEQUENCE\n"),
            [.transition]
        )
        let t = FNScript(string: "\n> OMITTED SEQUENCE\n").elements[0]
        XCTAssertEqual(t.elementType, "Transition")
        XCTAssertEqual(t.elementText, "OMITTED SEQUENCE")
    }

    func testCenteredActionStillDisambiguatedFromForcedTransition() {
        ParseAssertions.assertElementTypes(
            FNScript(string: "\n> TITLE CARD <\n\n> SMASH CUT TO:\n"),
            [.action, .transition]
        )
        XCTAssertTrue(FNScript(string: "\n> TITLE CARD <\n").elements[0].isCentered)
    }

    // MARK: - Synopsis `=`

    func testSynopsisAfterSectionHeading() {
        let script = FNScript(string: "\n# ACT ONE\n= Cold open beat\n\nINT. HOUSE - DAY\n")
        ParseAssertions.assertElementTypes(script, [.sectionHeading, .synopsis, .sceneHeading])
        let syn = script.elements.first { $0.elementType == "Synopsis" }
        XCTAssertTrue(syn?.elementText.contains("Cold open") ?? false)
        XCTAssertEqual(script.metrics.synopsisCount, 1)
    }

    // MARK: - Boneyard `/* */` (multiline + metrics)

    func testMultilineBoneyardSingleElementAndMetrics() {
        let script = FNScript(string: "\nINT. X - DAY\n\n/*\nghost one\nghost two\n*/\n\nVisible.\n")
        let boneyards = script.elements.filter { $0.elementType == "Boneyard" }
        XCTAssertEqual(boneyards.count, 1)
        XCTAssertTrue(boneyards[0].elementText.contains("ghost one"))
        XCTAssertTrue(boneyards[0].elementText.contains("ghost two"))
        let m = script.metrics
        XCTAssertEqual(m.boneyardElementCount, 1)
        XCTAssertFalse(script.elementsExcludingBoneyard.map(\.elementText).joined().contains("ghost"))
    }

    // MARK: - Scene numbers `#…#` on slug

    func testSceneNumberOnSlugEndAndStripFromElementText() {
        let script = FNScript(string: "\nINT. WAREHOUSE - NIGHT #42#\n\nAction.\n")
        let slug = script.elements.first { $0.elementType == "Scene Heading" }
        XCTAssertEqual(slug?.sceneNumber, "42")
        XCTAssertFalse(slug?.elementText.contains("#") ?? true)
        XCTAssertTrue(slug?.elementText.contains("WAREHOUSE") ?? false)
    }

    func testSceneNumberWithSuppressSceneNumbersExport() {
        let script = FNScript(string: "\nINT. HALL - DAY #9#\n\nEnd.\n")
        script.suppressSceneNumbers = true
        XCTAssertFalse(script.stringFromBody().contains("#"))
        script.suppressSceneNumbers = false
        XCTAssertTrue(script.stringFromBody().contains("#9#"))
    }

    // MARK: - Inline bold / italic / underline

    func testInlineHtmlFragmentBoldItalicUnderlineCombo() {
        XCTAssertEqual(
            FountainInlineMarkup.htmlFragment(from: "Say _*all*_ three."),
            "Say <em><u>all</u></em> three."
        )
    }

    func testInlineRichAttributedUnderlineAndItalic() {
        guard case .richAttributed(let attr) = FountainInlineMarkup.renderInline("_*x*_", mode: .attributedStringFromInlineMarkup) else {
            return XCTFail("expected rich")
        }
        XCTAssertEqual(String(attr.characters), "x")
        XCTAssertTrue(attr.runs.contains { $0[FountainInlineAttributedKeys.Underline.self] == true })
    }
}
