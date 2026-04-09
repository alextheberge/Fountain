//
//  SectionHeaderTests.swift
//
//  Copyright (c) 2013 Nima Yousefi & John August
//
//  MIT License — see BaseElementTests.swift
//

import XCTest
@testable import Fountain

class SectionHeaderTests: BaseElementTests {
    override func setUp() {
        super.setUp()
        loadTestFile("SectionHeaders")
    }

    private func sectionDepth(at index: Int) -> Int {
        return elements[index].sectionDepth
    }

    func testSectionHeader() {
        XCTAssertEqual(elementType(at: 0), "Section Heading", error(at: 0))
    }

    func testNoSpaceBetweenHashAndHeader() {
        XCTAssertEqual(elementType(at: 1), "Section Heading", error(at: 1))
    }

    func testAllCapsNoSpace() {
        XCTAssertEqual(elementType(at: 2), "Section Heading", error(at: 2))
    }

    func testAllCaps() {
        XCTAssertEqual(elementType(at: 3), "Section Heading", error(at: 3))
    }

    func testNumberOnly() {
        XCTAssertEqual(elementType(at: 4), "Section Heading", error(at: 4))
    }

    func testSectionDepth() {
        XCTAssertEqual(elementType(at: 5),   "Section Heading", error(at: 5))
        XCTAssertEqual(sectionDepth(at: 5),  2,                 error(at: 5))
        XCTAssertEqual(elementType(at: 6),   "Section Heading", error(at: 6))
        XCTAssertEqual(sectionDepth(at: 6),  3,                 error(at: 6))
    }
}
