//
//  BoneyardTests.swift
//
//  Copyright (c) 2013 Nima Yousefi & John August
//
//  MIT License — see BaseElementTests.swift
//

import XCTest
@testable import Fountain

class BoneyardTests: BaseElementTests {
    override func setUp() {
        super.setUp()
        loadTestFile("Boneyard")
    }

    func testSingleLineBoneyard() {
        XCTAssertEqual(elementType(at: 1), "Boneyard", error(at: 1))
    }

    func testMultiLineBoneyard() {
        XCTAssertEqual(elementType(at: 2), "Boneyard", error(at: 2))
    }
}
