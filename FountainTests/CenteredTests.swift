//
//  CenteredTests.swift
//
//  Copyright (c) 2013 Nima Yousefi & John August
//
//  MIT License — see BaseElementTests.swift
//

import XCTest
@testable import Fountain

class CenteredTests: BaseElementTests {
    override func setUp() {
        super.setUp()
        loadTestFile("CenteredText")
    }

    func testCentered() {
        XCTAssertEqual(elementType(at: 0), "Action", error(at: 0))
    }

    func testNotCentered() {
        XCTAssertEqual(elementType(at: 1), "Transition", error(at: 1))
    }

    func testNoSpacesBetweenBrackets() {
        XCTAssertEqual(elementType(at: 2), "Action", error(at: 2))
    }

    func testLotsOfSpaceBetweenBrackets() {
        XCTAssertEqual(elementType(at: 3), "Action", error(at: 3))
    }
}
