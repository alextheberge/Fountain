//
//  DialogueTests.swift
//
//  Copyright (c) 2013 Nima Yousefi & John August
//
//  MIT License — see BaseElementTests.swift
//

import XCTest
@testable import Fountain

class DialogueTests: BaseElementTests {
    override func setUp() {
        super.setUp()
        loadTestFile("Dialogue")
    }

    // MARK: - Character Cues

    func testCharacterCue() {
        XCTAssertEqual(elementType(at: 0), "Character", error(at: 0))
    }

    func testCueWithParenthetical() {
        XCTAssertEqual(elementType(at: 2), "Character", error(at: 2))
    }

    func testCueWithLowercaseContd() {
        XCTAssertEqual(elementType(at: 9), "Character", error(at: 9))
    }

    func testCharacterCueWithNumbers() {
        XCTAssertEqual(elementType(at: 20), "Character", error(at: 20))
    }

    func testCueCannotBeAllNumerical() {
        XCTAssertEqual(elementType(at: 23), "Character", error(at: 23))
    }

    func testCueCanBeIndented() {
        XCTAssertEqual(elementType(at: 27), "Character", error(at: 27))
    }

    // MARK: - Dual Dialogue

    func testCueWithCaret() {
        XCTAssertEqual(elementType(at: 18), "Character", error(at: 18))
    }

    func testMatchingDualDialogue() {
        XCTAssertEqual(elementType(at: 16), "Character", error(at: 16))
    }

    func testRemovalOfCaretMarkup() {
        XCTAssertEqual(elementText(at: 18), "EVE", error(at: 18))
    }

    // MARK: - Parentheticals

    func testParenthetical() {
        XCTAssertEqual(elementType(at: 5), "Parenthetical", error(at: 5))
    }

    func testParentheticalAtEndOfBlock() {
        XCTAssertEqual(elementType(at: 15), "Parenthetical", error(at: 15))
    }

    func testParentheticalCanBeIndented() {
        XCTAssertEqual(elementType(at: 28), "Parenthetical", error(at: 28))
    }

    // MARK: - Dialogue

    func testDialogue() {
        XCTAssertEqual(elementType(at: 1), "Dialogue", error(at: 1))
    }

    func testDialogueWithLineBreaks() {
        XCTAssertEqual(elementType(at: 12), "Dialogue", error(at: 12))
    }

    func testDialogueAllCaps() {
        XCTAssertEqual(elementType(at: 8), "Dialogue", error(at: 8))
    }

    func testDialogueWithEmptyLineInTheMiddle() {
        XCTAssertEqual(elementType(at: 26), "Dialogue", error(at: 26))
    }

    func testDialogueCanBeIndented() {
        XCTAssertEqual(elementType(at: 29), "Dialogue", error(at: 29))
    }
}
