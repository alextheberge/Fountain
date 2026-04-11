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
}
