import XCTest
#if canImport(PDFKit)
import PDFKit
#endif
import Fountain

/// Golden / snapshot checks for ``FountainFDXWriter`` and ``FountainPDFWriter`` (minimal export v1).
final class ExportGoldenFixtureTests: XCTestCase {
    private func normalizeFDX(_ s: String) -> String {
        s.replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func exportGoldenMinimalFountainText() throws -> String {
        let bundle = Bundle.module
        let url = try XCTUnwrap(bundle.url(forResource: "export-golden-minimal", withExtension: "fountain"))
        return try String(contentsOf: url, encoding: .utf8)
    }

    func testFDXWriterMatchesGoldenMinimalFixture() throws {
        let bundle = Bundle.module
        let goldenURL = try XCTUnwrap(bundle.url(forResource: "export-golden-minimal", withExtension: "fdx"))
        let fountainText = try exportGoldenMinimalFountainText()
        let expected = try String(contentsOf: goldenURL, encoding: .utf8)

        let script = FNScript(string: fountainText)
        let produced = try FountainFDXWriter().render(script)

        XCTAssertEqual(
            normalizeFDX(produced),
            normalizeFDX(expected),
            "FDX export drift — update export-golden-minimal.fdx only when intentionally changing FountainFDXWriter output."
        )
    }

    /// Phase **15.3** — **FDX** bytes must not depend on which parser built ``FNScript`` (export fidelity).
    func testFDXWriterGoldenMinimalFastParserMatchesTokenPipeline() throws {
        let raw = try exportGoldenMinimalFountainText()
        let fast = FNScript(string: raw, parser: .fast)
        let token = FNScript(string: raw, parser: .tokenPipeline)
        let fdxFast = try normalizeFDX(FountainFDXWriter().render(fast))
        let fdxToken = try normalizeFDX(FountainFDXWriter().render(token))
        XCTAssertEqual(fdxFast, fdxToken)
    }

    /// Phase **15.3** — full **HTML** document must match across parsers (pagination + body depend on element list).
    func testHTMLWriterGoldenMinimalFastParserMatchesTokenPipeline() throws {
        let raw = try exportGoldenMinimalFountainText()
        let fast = FNScript(string: raw, parser: .fast)
        let token = FNScript(string: raw, parser: .tokenPipeline)
        let htmlFast = try FountainHTMLWriter().render(fast)
        let htmlToken = try FountainHTMLWriter().render(token)
        XCTAssertEqual(htmlFast, htmlToken)
        XCTAssertTrue(htmlFast.contains("class='scene-heading'"))
        XCTAssertTrue(htmlFast.contains("INT. GOLDEN TEST - DAY"))
        XCTAssertTrue(htmlFast.contains("class='transition'"))
        XCTAssertTrue(htmlFast.contains("FADE OUT."))
    }

    /// Phase **15.3** — **JSON** interchange semantics (kinds + text + syntax pin) match across parsers; **IDs** may differ.
    func testFountainDocumentGoldenMinimalFastMatchesTokenPipelineSemantics() throws {
        let raw = try exportGoldenMinimalFountainText()
        let fastDoc = FNScript(string: raw, parser: .fast).asFountainDocument()
        let tokenDoc = FNScript(string: raw, parser: .tokenPipeline).asFountainDocument()
        XCTAssertEqual(fastDoc.fountainSyntaxVersion, tokenDoc.fountainSyntaxVersion)
        XCTAssertEqual(fastDoc.elements.map(\.kind), tokenDoc.elements.map(\.kind))
        XCTAssertEqual(fastDoc.elements.map(\.text), tokenDoc.elements.map(\.text))
        XCTAssertEqual(fastDoc.elements.map(\.metadata), tokenDoc.elements.map(\.metadata))
    }

    func testPDFWriterEmbedsFixtureBodyText() throws {
        #if canImport(PDFKit) && (os(macOS) || os(iOS) || os(tvOS) || os(visionOS))
        let fountainText = try exportGoldenMinimalFountainText()
        let script = FNScript(string: fountainText)
        let data = try FountainPDFWriter().renderPDFData(script)

        XCTAssertTrue(data.starts(with: [0x25, 0x50, 0x44, 0x46]), "PDF magic")
        let doc = try XCTUnwrap(PDFDocument(data: data))
        let full = doc.string ?? ""
        for needle in ["INT. GOLDEN TEST - DAY", "ALICE", "One line.", "FADE OUT."] {
            XCTAssertTrue(full.contains(needle), "PDFKit text extraction should find: \(needle)")
        }
        #else
        throw XCTSkip("PDFKit text extraction not used on this platform")
        #endif
    }

    func testPDFRenderBase64RoundTripsToSameBytes() throws {
        let fountainText = try exportGoldenMinimalFountainText()
        let script = FNScript(string: fountainText)
        let data = try FountainPDFWriter().renderPDFData(script)
        let roundTrip = try XCTUnwrap(Data(base64Encoded: data.base64EncodedString()))
        XCTAssertEqual(data, roundTrip, "Base64 encode/decode must reproduce identical PDF bytes")
    }
}
