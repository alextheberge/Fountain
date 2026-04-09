//
//  PageBreakTests.swift
//
//  Copyright (c) 2013 Nima Yousefi & John August
//
//  MIT License — see BaseElementTests.swift
//

import XCTest
@testable import Fountain

class PageBreakTests: BaseElementTests {
    override func setUp() {
        super.setUp()
        loadTestFile("PageBreaks")
    }

    func testPageBreak() {
        XCTAssertEqual(elementType(at: 1), "Page Break", error(at: 1))
    }

    func testLongPageBreakMark() {
        XCTAssertEqual(elementType(at: 3), "Page Break", error(at: 3))
    }
}
