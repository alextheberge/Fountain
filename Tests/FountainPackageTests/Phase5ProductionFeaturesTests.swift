import XCTest
import Fountain

/// Roadmap Phase 5.1–5.5 — production-oriented parse + export behavior (SwiftPM).
final class Phase5ProductionFeaturesTests: XCTestCase {
    // MARK: - 5.1 Page breaks

    func testPageBreakIsDistinctElement() {
        let script = FNScript(string: "\nINT. ROOM - DAY\n\n===\n\nFollow-on action.\n")
        ParseAssertions.assertElementTypes(
            script,
            [.sceneHeading, .pageBreak, .action]
        )
        XCTAssertEqual(script.elements[1].elementText.trimmingCharacters(in: .whitespaces), "===")
    }

    /// Phase 5.1 — ``FNPaginator`` treats `Page Break` as a hard flush (new page).
    func testPaginatorFlushesPageOnExplicitPageBreak() {
        let script = FNScript(string: "\nINT. STUDIO - DAY\n\nLine before break.\n\n===\n\nLine after break.\n")
        let paginator = FNPaginator(script: script)
        XCTAssertGreaterThanOrEqual(paginator.numberOfPages, 2)
        let hasFlush = (0 ..< paginator.numberOfPages).contains { i in
            paginator.pageAtIndex(i).contains { $0.elementType == "Page Break" }
        }
        XCTAssertTrue(hasFlush)
    }

    // MARK: - 5.2 Scene numbers

    func testSceneNumberCapturedOnStandardSlug() {
        // `#…#` is parsed when it appears at the end of the slugline (see `FastFountainParser`).
        let script = FNScript(string: "\nINT. WAREHOUSE - NIGHT #42#\n\nAction.\n")
        let slug = script.elements.first { $0.elementType == "Scene Heading" }
        XCTAssertEqual(slug?.sceneNumber, "42")
        XCTAssertFalse(slug?.elementText.contains("#") ?? true)
    }

    func testSuppressSceneNumbersOmitsPoundMarksInExport() {
        let script = FNScript(string: "\nINT. HALL - DAY #9#\n\nDone.\n")
        script.suppressSceneNumbers = false
        XCTAssertTrue(script.stringFromBody().contains("#9#"))
        script.suppressSceneNumbers = true
        XCTAssertFalse(script.stringFromBody().contains("#9#"))
    }

    // MARK: - 5.3 Boneyard

    func testBoneyardDoesNotReplaceFollowingAction() {
        let script = FNScript(string: "\nINT. X - DAY\n\n/* cut this */\n\nVisible line.\n")
        XCTAssertTrue(script.elements.contains { $0.elementType == "Boneyard" })
        let visible = script.elements.last { $0.elementType == "Action" }
        XCTAssertEqual(visible?.elementText, "Visible line.")
    }

    func testElementsExcludingBoneyardOmitsBoneyardType() {
        let script = FNScript(string: "\n/* only boneyard */\n")
        XCTAssertEqual(script.elements.count, 1)
        XCTAssertTrue(script.elementsExcludingBoneyard.isEmpty)
    }

    // MARK: - 5.4 Notes

    func testBracketNoteAfterBlankLine() {
        let script = FNScript(string: "\nINT. Z - DAY\n\nAction here.\n\n[[ remember prop ]]\n\nMore action.\n")
        let note = script.elements.first { $0.elementType == "Comment" }
        XCTAssertEqual(note?.elementText, "remember prop")
        XCTAssertTrue(script.elements.contains { $0.elementText == "More action." })
    }

    // MARK: - 5.5 Sections and synopses

    func testSectionDepthAndSynopsis() {
        let script = FNScript(string: "\n# Part one\n\n## Sequence A\n\n= story beat\n\nINT. HOUSE - DAY\n")
        let sections = script.elements.filter { $0.elementType == "Section Heading" }
        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections[0].sectionDepth, 1)
        XCTAssertEqual(sections[0].elementText.trimmingCharacters(in: .whitespaces), "Part one")
        XCTAssertEqual(sections[1].sectionDepth, 2)
        let syn = script.elements.first { $0.elementType == "Synopsis" }
        XCTAssertEqual(syn?.elementText, " story beat")
    }

    func testSynopsisAndSectionInCodableMetadata() {
        let script = FNScript(string: "\n### Deep\n\n= outline\n")
        let doc = FountainDocument(script: script)
        let section = doc.elements.first { $0.kind == .sectionHeading }
        let synopsis = doc.elements.first { $0.kind == .synopsis }
        XCTAssertEqual(section?.metadata[FountainMetadataKey.sectionDepth.rawValue], "3")
        XCTAssertEqual(synopsis?.text, " outline")
    }
}
