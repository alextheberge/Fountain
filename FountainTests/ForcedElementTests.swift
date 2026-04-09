//
//  ForcedElementTests.swift
//
//  Copyright (c) 2013 Nima Yousefi & John August
//
//  MIT License — see BaseElementTests.swift
//

import XCTest
@testable import Fountain

class ForcedElementTests: BaseElementTests {
    override func setUp() {
        super.setUp()
        loadTestFile("ForcedElements")
    }

    func testForcedAction() {
        XCTAssertEqual(elementType(at: 0), "Action", error(at: 0))
    }

    func testForcedCharacterCue() {
        XCTAssertEqual(elementType(at: 1), "Character", error(at: 1))
    }

    func testLyrics() {
        XCTAssertEqual(elementType(at: 4), "Lyrics", error(at: 4))
    }
}
