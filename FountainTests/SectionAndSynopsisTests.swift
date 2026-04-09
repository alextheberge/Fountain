//
//  SectionAndSynopsisTests.swift
//
//  Copyright (c) 2013 Nima Yousefi & John August
//
//  MIT License — see BaseElementTests.swift
//

import XCTest
@testable import Fountain

class SectionAndSynopsisTests: BaseElementTests {
    var script: FNScript!

    override func setUp() {
        super.setUp()
        guard let path = Bundle(for: type(of: self)).path(forResource: "Sections-Complex", ofType: "fountain") else {
            XCTFail("Could not find Sections-Complex.fountain")
            return
        }
        script = FNScript(file: path)
        elements = script.elements
    }

    private func sectionDepth(at index: Int) -> Int {
        let element = script.elements[index]
        if element.elementType != "Section Heading" {
            XCTFail("Element at index \(index) is not a Section Heading")
        }
        return element.sectionDepth
    }

    func testSectionHeader() {
        XCTAssertEqual(elementType(at: 3), "Section Heading", error(at: 3))
        XCTAssertEqual(sectionDepth(at: 3), 1, error(at: 3))
    }

    func testSectionHeaderWithoutPrecedingNewline() {
        XCTAssertEqual(elementType(at: 4), "Section Heading", error(at: 4))
        XCTAssertEqual(sectionDepth(at: 4), 2, error(at: 4))
    }

    func testSynopsisWithoutPrecedingNewline() {
        XCTAssertEqual(elementType(at: 1), "Synopsis", error(at: 1))
    }
}
