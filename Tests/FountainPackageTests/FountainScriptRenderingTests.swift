import XCTest
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

    /// Phase 8.2 — dual dialogue must emit grid markup (`ScriptCSS.css` / `FNHTMLScript`).
    func testStubWritersThrowNotImplemented() throws {
        let script = FNScript(string: "INT. S - DAY\n\nX.\n")
        XCTAssertThrowsError(try FountainFDXWriter().render(script)) { err in
            XCTAssertEqual(err as? FountainStubRendererError, .notImplemented("FountainFDXWriter"))
            let localized = err as? LocalizedError
            XCTAssertNotNil(localized?.errorDescription)
            XCTAssertTrue(localized?.errorDescription?.contains("FountainFDXWriter") ?? false)
        }
        XCTAssertThrowsError(try FountainPDFWriter().render(script)) { err in
            XCTAssertEqual(err as? FountainStubRendererError, .notImplemented("FountainPDFWriter"))
        }
    }

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
