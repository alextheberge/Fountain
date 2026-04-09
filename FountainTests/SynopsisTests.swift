//
//  SynopsisTests.swift
//
//  Copyright (c) 2013 Nima Yousefi & John August
//
//  MIT License — see BaseElementTests.swift
//

import XCTest
@testable import Fountain

class SynopsisTests: BaseElementTests {
    override func setUp() {
        super.setUp()
        loadTestFile("Synopses")
    }

    func testSynopsis() {
        XCTAssertEqual(elementType(at: 1), "Synopsis", error(at: 1))
    }

    func testSynopsisWithoutSpaceBetweenMarkAndText() {
        XCTAssertEqual(elementType(at: 3), "Synopsis", error(at: 3))
    }

    func testAllCapsSynopsis() {
        XCTAssertEqual(elementType(at: 5), "Synopsis", error(at: 5))
    }
}
