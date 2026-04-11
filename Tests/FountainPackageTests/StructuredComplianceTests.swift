import XCTest
import Fountain

/// Phase 7.2 — structured assertions on metadata and document kinds (beyond raw `elementType` strings).
final class StructuredComplianceTests: XCTestCase {
    func testSynopsisAndSectionKindsAndDepthMetadata() {
        let script = FNScript(string: "\n# ACT ONE\n= A beat.\n\nINT. HALL - DAY\n")
        ParseAssertions.assertScriptElementKinds(script, [.sectionHeading, .synopsis, .sceneHeading])
        let doc = script.asFountainDocument()
        ParseAssertions.assertMetadata(doc.elements[0], key: .sectionDepth, value: "1")
        XCTAssertEqual(doc.elements[1].kind, .synopsis)
    }

    func testDualDialogueMetadataOnDocument() {
        let script = FNScript(string: "\nA\nLine.\n\nB ^\nOther.\n")
        let chars = script.asFountainDocument().elements.filter { $0.kind == .character }
        XCTAssertEqual(chars.count, 2)
        ParseAssertions.assertMetadata(chars[0], key: .dualDialogue, value: "true")
        ParseAssertions.assertMetadata(chars[0], key: .dualDialogueColumn, value: "0")
        ParseAssertions.assertMetadata(chars[1], key: .dualDialogueColumn, value: "1")
    }

    func testFountainDocumentAliasMatchesAsFountainDocument() {
        let script = FNScript(string: "\nINT. ALIAS - DAY\n\nText.\n")
        let a = script.fountainDocument
        let b = script.asFountainDocument()
        XCTAssertEqual(a.elements.map(\.kind), b.elements.map(\.kind))
        XCTAssertEqual(a.elements.map(\.text), b.elements.map(\.text))
        XCTAssertEqual(a.fountainSyntaxVersion, b.fountainSyntaxVersion)
    }

    func testBoneyardOmittedFromDialogueStyleSlice() {
        let script = FNScript(string: "\nVOICE\nHello.\n\n/* cut */\n\nOTHER\nBye.\n")
        let body = script.elementsExcludingBoneyard
        let dialogueish = body.filter { ["Dialogue", "Character"].contains($0.elementType) }
        XCTAssertEqual(dialogueish.map(\.elementType), ["Character", "Dialogue", "Character", "Dialogue"])
    }
}
