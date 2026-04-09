//
//  MultilineActionTests.swift
//
//  Copyright (c) 2013 Nima Yousefi & John August
//
//  MIT License — see BaseElementTests.swift
//

import XCTest
@testable import Fountain

class MultilineActionTests: BaseElementTests {
    override func setUp() {
        super.setUp()
        loadTestFile("MultilineAction")
    }

    func testMultilineAction() {
        XCTAssertEqual(elementType(at: 0), "Action", error(at: 0))
        XCTAssertEqual(elementType(at: 1), "Action", error(at: 1))
        XCTAssertEqual(elementType(at: 2), "Action", error(at: 2))
    }
}
