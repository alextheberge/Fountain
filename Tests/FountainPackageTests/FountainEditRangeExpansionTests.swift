import XCTest
import Fountain

final class FountainEditRangeExpansionTests: XCTestCase {
    func testExpandToFullLineCoversPartialSelection() {
        let s = "aa\nbb\ncc"
        guard let lo = s.utf16Offset(of: "aa\n", atEnd: true),
            let hi = s.utf16Offset(of: "aa\nb", atEnd: true)
        else {
            XCTFail("offsets")
            return
        }
        let expanded = FountainEditRangeExpansion.expandToFullLineUTF16Range(lo..<hi, in: s)
        guard let expLo = s.utf16Offset(of: "aa\n", atEnd: true),
            let expHi = s.utf16Offset(of: "bb\n", atEnd: true)
        else {
            XCTFail("expected")
            return
        }
        XCTAssertEqual(expanded.lowerBound, expLo)
        XCTAssertEqual(expanded.upperBound, expHi)
    }

    func testExpandToStructuralAnchorStopsAtBlankLineAbove() {
        let s = "INT. ROOM - DAY\n\nAction here.\nMore action.\n"
        let needle = "More"
        guard let r = s.range(of: needle) else {
            XCTFail("needle")
            return
        }
        let lo = r.lowerBound.utf16Offset(in: s)
        let hi = r.upperBound.utf16Offset(in: s)
        let expanded = FountainEditRangeExpansion.expandToStructuralAnchorUTF16Range(lo..<hi, in: s)
        let slice = (s as NSString).substring(with: NSRange(location: expanded.lowerBound, length: expanded.upperBound - expanded.lowerBound))
        XCTAssertTrue(slice.contains("Action here"))
        XCTAssertFalse(slice.contains("INT."))
    }

    func testExpandToStructuralAnchorStopsBeforeFollowingSlug() {
        let s = "INT. A - DAY\n\nHello.\n\nINT. B - DAY\n"
        guard let r = s.range(of: "Hello") else {
            XCTFail("needle")
            return
        }
        let lo = r.lowerBound.utf16Offset(in: s)
        let hi = r.upperBound.utf16Offset(in: s)
        let expanded = FountainEditRangeExpansion.expandToStructuralAnchorUTF16Range(lo..<hi, in: s)
        let slice = (s as NSString).substring(with: NSRange(location: expanded.lowerBound, length: expanded.upperBound - expanded.lowerBound))
        XCTAssertTrue(slice.contains("Hello"))
        XCTAssertFalse(slice.contains("INT. B"))
    }
}

private extension String {
    /// UTF-16 offset of `needle`'s lower bound, or its upper bound when `atEnd` is true.
    func utf16Offset(of needle: String, atEnd: Bool) -> Int? {
        guard let r = range(of: needle) else { return nil }
        return (atEnd ? r.upperBound : r.lowerBound).utf16Offset(in: self)
    }
}
