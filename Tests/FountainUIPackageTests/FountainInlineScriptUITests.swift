import XCTest
import SwiftUI
import FountainCore
import FountainUI

final class FountainInlineScriptUITests: XCTestCase {
    func testUsesAttributedInlineSkipsCharacterAndSceneHeading() {
        XCTAssertFalse(FountainUIScriptElementLineContent.usesAttributedInline(for: .character))
        XCTAssertFalse(FountainUIScriptElementLineContent.usesAttributedInline(for: .sceneHeading))
        XCTAssertFalse(FountainUIScriptElementLineContent.usesAttributedInline(for: .pageBreak))
        XCTAssertTrue(FountainUIScriptElementLineContent.usesAttributedInline(for: .action))
        XCTAssertTrue(FountainUIScriptElementLineContent.usesAttributedInline(for: .dialogue))
    }

    func testAttributedActionPreservesBoldInnerText() {
        let fragment = FountainInlineMarkup.attributedFragment(from: "Say **now**.")
        let plain = String(fragment.characters)
        XCTAssertTrue(plain.contains("now"), "Expected stripped inner text in character view, got: \(plain)")
        XCTAssertFalse(plain.contains("**"), "Bold markers should not appear in rendered character content")
    }
}

@MainActor
final class FountainInlineScriptUIRenderingTests: XCTestCase {
    func testFountainViewRendersActionWithBoldMarkers() {
        let doc = FountainDocument(script: FNScript(string: "\nINT. X - DAY\n\nAction with **bold** word.\n"))
        let renderer = ImageRenderer(content: FountainView(document: doc))
        renderer.scale = 1
        XCTAssertNotNil(renderer.cgImage)
    }
}
