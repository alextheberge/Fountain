import XCTest
import Foundation
import Fountain

/// Roadmap Phase 6 — inline plain vs rich policy, underline attribute, delimiter table.
final class Phase6InlinePolicyTests: XCTestCase {
    func testRenderInlinePlainPreservesMarkers() {
        let s = "pre **bold** post"
        guard case .plainMarkersPreserved(let out) = FountainInlineMarkup.renderInline(s, mode: .preserveMarkersInPlaintext) else {
            return XCTFail("Expected plain")
        }
        XCTAssertEqual(out, s)
    }

    func testRenderInlineRichStripsMarkers() {
        let s = "pre **bold** post"
        guard case .richAttributed(let attr) = FountainInlineMarkup.renderInline(s, mode: .attributedStringFromInlineMarkup) else {
            return XCTFail("Expected rich")
        }
        XCTAssertEqual(String(attr.characters), "pre bold post")
        XCTAssertNotNil(attr.runs.first { $0.inlinePresentationIntent?.contains(.stronglyEmphasized) == true })
    }

    func testAttributedUnderlineOnlySpanCarriesUnderlineKey() {
        let attr = FountainInlineMarkup.attributedFragment(from: "_only_")
        XCTAssertEqual(String(attr.characters), "only")
        XCTAssertTrue(attr.runs.contains { $0[FountainInlineAttributedKeys.Underline.self] == true })
    }

    func testAttributedCombinedUnderlineSetsUnderlineKey() {
        let attr = FountainInlineMarkup.attributedFragment(from: "_*UI*_")
        XCTAssertEqual(String(attr.characters), "UI")
        XCTAssertTrue(attr.runs.contains { $0[FountainInlineAttributedKeys.Underline.self] == true })
        XCTAssertNotNil(attr.runs.first { $0.inlinePresentationIntent?.contains(.emphasized) == true })
    }

    func testFountainInlineRenderingModeCasesDocumented() {
        XCTAssertEqual(FountainInlineRenderingMode.allCases.count, 2)
    }
}
