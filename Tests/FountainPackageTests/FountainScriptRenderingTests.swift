import XCTest
import Fountain

final class FountainScriptRenderingTests: XCTestCase {
    func testPlaintextWriterRoundTripBody() throws {
        let script = FNScript(string: "\nINT. Z - DAY\n\nHello.\n")
        let writer = FountainPlaintextWriter()
        let out = try writer.render(script)
        XCTAssertTrue(out.contains("INT. Z - DAY"))
        XCTAssertTrue(out.contains("Hello."))
    }

    func testInlineRenderingModeEnumIsStable() {
        XCTAssertTrue(FountainInlineRenderingMode.allCases.contains(.preserveMarkersInPlaintext))
    }

    func testMarkdownWriterIncludesSceneHeadingAndBody() throws {
        let script = FNScript(string: "\nINT. MD - DAY\n\nHello.\n")
        let md = try FountainMarkdownWriter().render(script)
        XCTAssertTrue(md.contains("## INT. MD - DAY"))
        XCTAssertTrue(md.contains("Hello."))
    }

    func testFNHTMLScriptRenderProducesDocument() throws {
        let script = FNScript(string: "\nINT. H - DAY\n\n*emphasis* in action.\n")
        let htmlGen = FNHTMLScript(script: script)
        let out = try htmlGen.render(script)
        XCTAssertTrue(out.hasPrefix("<!DOCTYPE html>"))
        XCTAssertTrue(out.contains("<em>emphasis</em>"))
    }
}
