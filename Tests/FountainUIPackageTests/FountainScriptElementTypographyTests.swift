import XCTest
import FountainCore
import FountainUI

final class FountainScriptElementTypographyTests: XCTestCase {
    func testDualDialogueColumnReadsMetadata() {
        let left = ScriptElement(
            kind: .character,
            text: "ADAM",
            metadata: [
                FountainMetadataKey.dualDialogue.rawValue: "true",
                FountainMetadataKey.dualDialogueColumn.rawValue: "0",
            ]
        )
        let right = ScriptElement(
            kind: .character,
            text: "EVE",
            metadata: [
                FountainMetadataKey.dualDialogue.rawValue: "true",
                FountainMetadataKey.dualDialogueColumn.rawValue: "1",
            ]
        )
        XCTAssertEqual(FountainScriptElementTypography.dualDialogueColumn(left), 0)
        XCTAssertEqual(FountainScriptElementTypography.dualDialogueColumn(right), 1)
        XCTAssertEqual(FountainScriptElementTypography.paddingLeading(for: left), 0)
        XCTAssertGreaterThan(FountainScriptElementTypography.paddingLeading(for: right), 0)
    }
}
