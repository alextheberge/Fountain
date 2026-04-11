import XCTest
#if canImport(PDFKit)
import PDFKit
#endif
import Fountain

/// Phase 8 — ``FountainScriptRendering`` conformers (plaintext, JSON, Markdown, HTML, stubs).
final class FountainScriptRenderingTests: XCTestCase {
    func testPlaintextWriterRoundTripBody() throws {
        let script = FNScript(string: "\nINT. Z - DAY\n\nHello.\n")
        let writer = FountainPlaintextWriter()
        let out = try writer.render(script)
        XCTAssertTrue(out.contains("INT. Z - DAY"))
        XCTAssertTrue(out.contains("Hello."))
    }

    /// Phase 8.1 — protocol path must stay aligned with ``FountainWriter`` export.
    func testFountainPlaintextWriterMatchesFountainWriterDocument() throws {
        let script = FNScript(string: "Title: Parity\n\nINT. P - DAY\n\nDone.\n")
        let fromProtocol = try FountainPlaintextWriter().render(script)
        let fromStatic = FountainWriter.documentFromScript(script)
        XCTAssertEqual(fromProtocol, fromStatic)
    }

    func testInlineRenderingModeEnumIsStable() {
        XCTAssertTrue(FountainInlineRenderingMode.allCases.contains(.preserveMarkersInPlaintext))
        XCTAssertTrue(FountainInlineRenderingMode.allCases.contains(.attributedStringFromInlineMarkup))
    }

    func testJSONWriterEncodesDocument() throws {
        let script = FNScript(string: "\nINT. JSON - DAY\n\nHello.\n")
        let json = try FountainJSONWriter(prettyPrinted: true).render(script)
        XCTAssertTrue(json.contains("\"fountainSyntaxVersion\""))
        XCTAssertTrue(json.contains("INT. JSON - DAY"))
    }

    func testMarkdownWriterIncludesSceneHeadingAndBody() throws {
        let script = FNScript(string: "\nINT. MD - DAY\n\nHello.\n")
        let md = try FountainMarkdownWriter().render(script)
        XCTAssertTrue(md.contains("## INT. MD - DAY"))
        XCTAssertTrue(md.contains("Hello."))
    }

    func testMarkdownWriterEmitsLyricsAndBracketNotes() throws {
        let script = FNScript(string: "\nINT. X - DAY\n\n~♪ Sing\n\nBOB\nHi.\n\n[[ note ]]\n\nOut.\n")
        XCTAssertEqual(
            script.elements.map(\.elementType),
            ["Scene Heading", "Lyrics", "Character", "Dialogue", "Comment", "Action"]
        )
        let md = try FountainMarkdownWriter().render(script)
        XCTAssertTrue(md.contains("## INT. X"))
        XCTAssertTrue(md.contains("Sing"))
        XCTAssertTrue(md.contains("> *"))
        XCTAssertTrue(md.contains("[[") && md.contains("note"))
    }

    func testFNHTMLScriptRenderProducesDocument() throws {
        let script = FNScript(string: "\nINT. H - DAY\n\n*emphasis* in action.\n")
        let htmlGen = FNHTMLScript(script: script)
        let out = try htmlGen.render(script)
        XCTAssertTrue(out.hasPrefix("<!DOCTYPE html>"))
        XCTAssertTrue(out.contains("<em>emphasis</em>"))
    }

    /// Phase 8.2 — ``FountainHTMLWriter`` is the thin ``FountainScriptRendering`` adapter over ``FNHTMLScript``.
    func testFountainHTMLWriterMatchesFreshFNHTMLScript() throws {
        let script = FNScript(string: "\nINT. HW - DAY\n\n**bold** act.\n")
        let viaWriter = try FountainHTMLWriter().render(script)
        let viaClass = try FNHTMLScript(script: script).render(script)
        XCTAssertEqual(viaWriter, viaClass)
        XCTAssertTrue(viaWriter.contains("<strong>bold</strong>"))
    }

    /// Phase 8.4 — FDX is well-formed XML Final Draft can import; PDF is base64-encoded bytes.
    func testFDXWriterEmitsFinalDraftXML() throws {
        let script = FNScript(string: "INT. S - DAY\n\nBOB\nHello.\n\n> FADE OUT.\n")
        let fdx = try FountainFDXWriter().render(script)
        XCTAssertTrue(fdx.hasPrefix("<?xml"))
        XCTAssertTrue(fdx.contains("<FinalDraft"))
        XCTAssertTrue(fdx.contains("DocumentType=\"Script\""))
        XCTAssertTrue(fdx.contains("<Paragraph Type=\"Scene Heading\">"))
        XCTAssertTrue(fdx.contains("INT. S - DAY"))
        XCTAssertTrue(fdx.contains("<Paragraph Type=\"Character\">"))
        XCTAssertTrue(fdx.contains("BOB"))
        XCTAssertTrue(fdx.contains("<Paragraph Type=\"Dialogue\">"))
        XCTAssertTrue(fdx.contains("Hello."))
        XCTAssertTrue(fdx.contains("<Paragraph Type=\"Transition\">"))
        XCTAssertTrue(fdx.contains("FADE OUT."))
        XCTAssertTrue(fdx.contains("<PageLayout"), "Phase 8.7 — layout margins for Final Draft import")
        XCTAssertTrue(fdx.contains("<ElementSettings Type=\"Scene Heading\">"))
        XCTAssertTrue(fdx.contains("<MoresAndContinueds>"))
        XCTAssertTrue(fdx.contains("DialogueBottom=\"(MORE)\""))
    }

    func testPDFWriterProducesValidPDFBytes() throws {
        let script = FNScript(string: "INT. P - DAY\n\nAction here.\n")
        let writer = FountainPDFWriter()
        let b64 = try writer.render(script)
        let data = try XCTUnwrap(Data(base64Encoded: b64))
        XCTAssertGreaterThan(data.count, 500)
        XCTAssertTrue(data.starts(with: [0x25, 0x50, 0x44, 0x46]), "PDF magic %PDF")
        let data2 = try writer.renderPDFData(script)
        XCTAssertTrue(data2.starts(with: [0x25, 0x50, 0x44, 0x46]))
    }

    #if canImport(PDFKit)
    func testPDFWriterMultiPageDocumentHasAtLeastTwoPages() throws {
        let filler = String(repeating: "WORD ", count: 800)
        let script = FNScript(string: "INT. LONG SCENE - DAY\n\n\(filler)\n")
        let data = try FountainPDFWriter().renderPDFData(script)
        let doc = try XCTUnwrap(PDFDocument(data: data))
        XCTAssertGreaterThanOrEqual(doc.pageCount, 2, "Phase 8.8 — overflow should begin a new PDF page")
    }

    /// Phase 8.8 — ``FNPaginator`` + ``FountainPDFWriter/renderPDFDataPaginated(script:)`` (FountainHTML extension).
    func testPDFWriterPaginatedExportIsValidPDF() throws {
        let script = FNScript(string: """
        Title: Paginated Export Test

        INT. ROOM - DAY

        Action before break.

        ===

        After explicit page break.
        """)
        let data = try FountainPDFWriter().renderPDFDataPaginated(script: script)
        let doc = try XCTUnwrap(PDFDocument(data: data))
        XCTAssertGreaterThanOrEqual(doc.pageCount, 1)
        let combined = (0 ..< doc.pageCount).compactMap { doc.page(at: $0)?.string }.joined()
        XCTAssertTrue(combined.contains("INT.") || combined.contains("ROOM"))
    }

    func testPDFWriterFlatExportIncludesDraftTitleInExtractedText() throws {
        let script = FNScript(string: "Title: Draft Title Alpha\n\nINT. Z - DAY\n\nBody.\n")
        let data = try FountainPDFWriter().renderPDFData(script)
        let doc = try XCTUnwrap(PDFDocument(data: data))
        let combined = (0 ..< doc.pageCount).compactMap { doc.page(at: $0)?.string }.joined()
        XCTAssertTrue(combined.contains("Draft Title Alpha"), "Header should repeat title-page Title key")
    }
    #endif

    func testFNHTMLScriptDualDialogueContainsGridClasses() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "package-dual-dialogue", withExtension: "fountain"))
        let text = try String(contentsOf: url, encoding: .utf8)
        let script = FNScript(string: text)
        let htmlGen = FNHTMLScript(script: script)
        let out = try htmlGen.render(script)
        XCTAssertTrue(out.contains("class='dual-dialogue'"), "wrapper div")
        XCTAssertTrue(out.contains("dual-dialogue-left"))
        XCTAssertTrue(out.contains("dual-dialogue-right"))
        XCTAssertTrue(out.contains("ADAM") && out.contains("EVE"))
    }
}
