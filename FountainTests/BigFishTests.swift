//
//  BigFishTests.swift
//
//  Copyright (c) 2013 Nima Yousefi & John August
//
//  MIT License — see BaseElementTests.swift
//

import XCTest
@testable import Fountain

class BigFishTests: XCTestCase {
    var script: FNScript!

    override func setUp() {
        super.setUp()
        guard let path = Bundle(for: type(of: self)).path(forResource: "Big Fish", ofType: "fountain") else {
            XCTFail("Could not find Big Fish.fountain")
            return
        }
        script = FNScript(file: path)
    }

    // MARK: - Body tests

    func testScriptLoading() {
        XCTAssertNotNil(script, "The script wasn't able to load.")
    }

    func testSceneHeadings() {
        for index in [11, 17, 31, 50] {
            let element = script.elements[index]
            XCTAssertEqual(element.elementType, "Scene Heading", "Index \(index): [\(element.elementType)] \(element.elementText)")
        }
    }

    func testCharacters() {
        for index in [6, 9, 13, 19, 39] {
            let element = script.elements[index]
            XCTAssertEqual(element.elementType, "Character", "Index \(index): [\(element.elementType)] \(element.elementText)")
        }
    }

    func testDialogues() {
        for index in [7, 10, 14, 16, 20, 24] {
            let element = script.elements[index]
            XCTAssertEqual(element.elementType, "Dialogue", "Index \(index): [\(element.elementType)] \(element.elementText)")
        }
    }

    func testParentheticals() {
        for index in [15, 23, 40, 70] {
            let element = script.elements[index]
            XCTAssertEqual(element.elementType, "Parenthetical", "Index \(index): [\(element.elementType)] \(element.elementText)")
        }
    }

    func testTransitions() {
        for index in [209] {
            let element = script.elements[index]
            XCTAssertEqual(element.elementType, "Transition", "Index \(index): [\(element.elementType)] \(element.elementText)")
        }
    }

    func testPageBreaks() {
        for index in [1] {
            let element = script.elements[index]
            XCTAssertEqual(element.elementType, "Page Break", "Index \(index): [\(element.elementType)] \(element.elementText)")
        }
    }

    func testActions() {
        for index in [0, 3, 38] {
            let element = script.elements[index]
            XCTAssertEqual(element.elementType, "Action", "Index \(index): [\(element.elementType)] \(element.elementText)")
        }
    }

    // MARK: - Title page tests

    func testTitlePage() {
        XCTAssertEqual(script.titlePage.count, 6)
    }

    func testTitle() {
        let title = script.titlePage[0]["title"]
        XCTAssertEqual(title?.count, 1)
        XCTAssertEqual(title?[0], "Big Fish")
    }

    func testCredit() {
        let credit = script.titlePage[1]["credit"]
        XCTAssertEqual(credit?.count, 1)
        XCTAssertEqual(credit?[0], "written by")
    }

    func testNotes() {
        let notes = script.titlePage[4]["notes"]
        XCTAssertEqual(notes?.count, 3)
        XCTAssertEqual(notes?[0], "FINAL PRODUCTION DRAFT")
    }
}
