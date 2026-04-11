import XCTest
import Fountain

/// Polish backlog — structural matchers without regex; gap-matrix regression for **P** areas (sections, forced `@`, lyrics, bracket notes).
final class PolishStructuralAndGapTests: XCTestCase {
    // MARK: - Structural matchers (Phase 3.5 polish)

    func testPageBreakAndSynopsisDisambiguation() {
        XCTAssertTrue(FountainStructuralLineMatchers.isPageBreakLine("==="))
        XCTAssertTrue(FountainStructuralLineMatchers.isPageBreakLine("==== \t"))
        XCTAssertFalse(FountainStructuralLineMatchers.isPageBreakLine("= synopsis"))
        XCTAssertTrue(FountainStructuralLineMatchers.isSynopsisLine(trimmedLine: "= beat"))
    }

    func testBracketNoteLineShape() {
        XCTAssertTrue(FountainStructuralLineMatchers.isBracketNoteLine(newlinesBefore: 1, line: "[[ prop note ]]"))
        XCTAssertTrue(FountainStructuralLineMatchers.isBracketNoteLine(newlinesBefore: 2, line: "  [[  x  ]]  "))
        XCTAssertFalse(FountainStructuralLineMatchers.isBracketNoteLine(newlinesBefore: 0, line: "[[ x ]]"))
        XCTAssertFalse(FountainStructuralLineMatchers.isBracketNoteLine(newlinesBefore: 1, line: "[[ bad ] tail ]]"))
    }

    func testBoneyardLineShapes() {
        XCTAssertTrue(FountainStructuralLineMatchers.isBoneyardOpenLine("/* note"))
        XCTAssertTrue(FountainStructuralLineMatchers.isSingleLineBoneyard("/* x */"))
        XCTAssertTrue(FountainStructuralLineMatchers.isBoneyardCloseLine("end */"))
        XCTAssertFalse(FountainStructuralLineMatchers.isSingleLineBoneyard("/* only open"))
    }

    func testTransitionTOAndAllCapsCue() {
        XCTAssertTrue(FountainStructuralLineMatchers.isTransitionEndingInTO("CUT TO:"))
        XCTAssertTrue(FountainStructuralLineMatchers.isTransitionEndingInTO("  SMASH CUT TO:  "))
        XCTAssertFalse(FountainStructuralLineMatchers.isTransitionEndingInTO("Cut to:"))
        XCTAssertTrue(FountainStructuralLineMatchers.isAllCapsCharacterCue("BOB"))
        XCTAssertTrue(FountainStructuralLineMatchers.isAllCapsCharacterCue("MOM (cont'd)"))
        XCTAssertTrue(FountainStructuralLineMatchers.isAllCapsCharacterCue("DAD (CONT'D)"))
        XCTAssertFalse(FountainStructuralLineMatchers.isAllCapsCharacterCue("Bob"))
    }

    // MARK: - Gap matrix (parser + metadata)

    func testTripleSectionHeadingDepthInDocument() {
        let script = FNScript(string: "\n### Deep act\n\nINT. HALL - DAY\n")
        ParseAssertions.assertScriptElementKinds(script, [.sectionHeading, .sceneHeading])
        let doc = script.asFountainDocument()
        ParseAssertions.assertMetadata(doc.elements[0], key: .sectionDepth, value: "3")
    }

    func testForcedCharacterAtParsesCharacterElement() {
        ParseAssertions.assertElementTypes(
            FNScript(string: "\n@SOMEONE IN MASK\nThey speak.\n"),
            [.character, .dialogue]
        )
    }

    func testLyricsTildeMultiLineFromParser() {
        ParseAssertions.assertElementTypes(
            FNScript(string: "\n~♪ Line one\n~♪ Line two\n\nINT. R - DAY\n"),
            [.lyrics, .lyrics, .sceneHeading]
        )
    }

    func testBracketNoteParsesAsCommentElement() {
        let script = FNScript(string: "\nINT. Z - DAY\n\n[[ wardrobe ]]\n\nOut.\n")
        XCTAssertTrue(script.elements.contains { $0.elementType == "Comment" })
        ParseAssertions.assertElementTypes(script, [.sceneHeading, .comment, .action])
    }
}
