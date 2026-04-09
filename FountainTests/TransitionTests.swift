//
//  TransitionTests.swift
//
//  Copyright (c) 2013 Nima Yousefi & John August
//
//  MIT License — see BaseElementTests.swift
//

import XCTest
@testable import Fountain

class TransitionTests: BaseElementTests {
    override func setUp() {
        super.setUp()
        loadTestFile("Transitions")
    }

    func testCutTo() {
        XCTAssertEqual(elementType(at: 0), "Transition", error(at: 0))
    }

    func testSmashCutTo() {
        XCTAssertEqual(elementType(at: 1), "Transition", error(at: 1))
    }

    func testFadeToBlack() {
        XCTAssertEqual(elementType(at: 2), "Transition", error(at: 2))
    }

    func testForcedTransition() {
        XCTAssertEqual(elementType(at: 3), "Transition", error(at: 3))
    }

    func testNotTransitionWithTrailingSpaces() {
        XCTAssertNotEqual(elementType(at: 4), "Transition", error(at: 4))
    }

    func testCustomTransitionEndingWithTo() {
        XCTAssertEqual(elementType(at: 5), "Transition", error(at: 5))
    }

    func testMinimumTransition() {
        XCTAssertEqual(elementType(at: 6), "Transition", error(at: 6))
    }
}
