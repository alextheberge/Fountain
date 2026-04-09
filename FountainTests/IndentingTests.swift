//
//  IndentingTests.swift
//
//  Copyright (c) 2013 Nima Yousefi & John August
//
//  MIT License — see BaseElementTests.swift
//

import XCTest
@testable import Fountain

class IndentingTests: BaseElementTests {
    override func setUp() {
        super.setUp()
        loadTestFile("Indenting")
    }

    func testTransition() {
        XCTAssertEqual(elementType(at: 0), "Transition", error(at: 0))
    }

    func testCharacterCue() {
        XCTAssertEqual(elementType(at: 3), "Character", error(at: 3))
    }

    func testDialogue() {
        XCTAssertEqual(elementType(at: 4), "Dialogue", error(at: 4))
    }

    func testParenthetical() {
        XCTAssertEqual(elementType(at: 6), "Parenthetical", error(at: 6))
    }
}
