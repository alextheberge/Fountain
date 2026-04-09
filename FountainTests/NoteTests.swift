//
//  NoteTests.swift
//
//  Copyright (c) 2013 Nima Yousefi & John August
//
//  MIT License — see BaseElementTests.swift
//

import XCTest
@testable import Fountain

class NoteTests: BaseElementTests {
    override func setUp() {
        super.setUp()
        loadTestFile("Notes")
    }

    func testSingleLineNote() {
        XCTAssertEqual(elementType(at: 1), "Comment", error(at: 1))
    }
}
