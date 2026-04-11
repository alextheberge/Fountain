import XCTest
import SwiftUI
import FountainCore
import FountainUI

@MainActor
final class FountainViewRenderingTests: XCTestCase {
    func testImageRendererProducesBitmapForMinimalScript() {
        let doc = FountainDocument(script: FNScript(string: "\nINT. RENDER - DAY\n\nALICE\nLine.\n"))
        let renderer = ImageRenderer(content: FountainView(document: doc))
        renderer.scale = 1
        XCTAssertNotNil(renderer.cgImage, "FountainView should layout without crashing")
    }

    func testImageRendererDualDialogueFixture() {
        let raw = "\nINT. TWO COLUMN - DAY\n\nADAM\nYes.\n\nEVE ^\nNo.\n"
        let doc = FountainDocument(script: FNScript(string: raw))
        let renderer = ImageRenderer(content: FountainView(document: doc))
        renderer.scale = 1
        XCTAssertNotNil(renderer.cgImage)
    }

    /// Phase **15.3** — narrow width + tall canvas should still layout (regression guard for padding / `LazyVStack`).
    func testImageRendererNarrowProposedSizeStillBitmap() {
        let doc = FountainDocument(script: FNScript(string: "\nINT. NARROW - DAY\n\nBOB\nA longer dialogue line that wraps in a thin column.\n"))
        let renderer = ImageRenderer(content: FountainView(document: doc))
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(width: 280, height: 900)
        XCTAssertNotNil(renderer.cgImage)
    }
}
