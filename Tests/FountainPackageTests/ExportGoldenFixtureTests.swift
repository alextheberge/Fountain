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

    func testFDXWriterMatchesGoldenMinimalFixture() throws {
        let bundle = Bundle.module
        let fountainURL = try XCTUnwrap(bundle.url(forResource: "export-golden-minimal", withExtension: "fountain"))
        let goldenURL = try XCTUnwrap(bundle.url(forResource: "export-golden-minimal", withExtension: "fdx"))
        let fountainText = try String(contentsOf: fountainURL, encoding: .utf8)
        let expected = try String(contentsOf: goldenURL, encoding: .utf8)

        let script = FNScript(string: fountainText)
        let produced = try FountainFDXWriter().render(script)

        XCTAssertEqual(
            normalizeFDX(produced),
            normalizeFDX(expected),
            "FDX export drift — update export-golden-minimal.fdx only when intentionally changing FountainFDXWriter output."
        )
    }

    func testPDFWriterEmbedsFixtureBodyText() throws {
        #if canImport(PDFKit) && (os(macOS) || os(iOS) || os(tvOS) || os(visionOS))
        let bundle = Bundle.module
        let fountainURL = try XCTUnwrap(bundle.url(forResource: "export-golden-minimal", withExtension: "fountain"))
        let fountainText = try String(contentsOf: fountainURL, encoding: .utf8)
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
        let bundle = Bundle.module
        let fountainURL = try XCTUnwrap(bundle.url(forResource: "export-golden-minimal", withExtension: "fountain"))
        let fountainText = try String(contentsOf: fountainURL, encoding: .utf8)
        let script = FNScript(string: fountainText)
        let data = try FountainPDFWriter().renderPDFData(script)
        let roundTrip = try XCTUnwrap(Data(base64Encoded: data.base64EncodedString()))
        XCTAssertEqual(data, roundTrip, "Base64 encode/decode must reproduce identical PDF bytes")
    }
}
