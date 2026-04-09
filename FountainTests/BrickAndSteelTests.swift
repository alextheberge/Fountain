//
//  BrickAndSteelTests.swift
//
//  Copyright (c) 2013 Nima Yousefi & John August
//
//  MIT License — see BaseElementTests.swift
//

import XCTest
@testable import Fountain

class BrickAndSteelTests: XCTestCase {
    var script: FNScript!

    override func setUp() {
        super.setUp()
        guard let path = Bundle(for: type(of: self)).path(forResource: "Brick And Steel", ofType: "txt") else {
            XCTFail("Could not find Brick And Steel.txt")
            return
        }
        script = FNScript(file: path)
    }

    // MARK: - Body tests

    func testScriptLoading() {
        XCTAssertNotNil(script, "The script wasn't able to load.")
    }

    func testSceneHeadings() {
        for index in [0, 23, 32, 40, 49, 55] {
            let element = script.elements[index]
            XCTAssertEqual(element.elementType, "Scene Heading", "Index \(index): [\(element.elementType)] \(element.elementText)")
        }
    }

    func testCharacters() {
        for index in [3, 5, 18, 20, 25] {
            let element = script.elements[index]
            XCTAssertEqual(element.elementType, "Character", "Index \(index): [\(element.elementType)] \(element.elementText)")
        }
    }

    func testDialogues() {
        for index in [4, 12, 27] {
            let element = script.elements[index]
            XCTAssertEqual(element.elementType, "Dialogue", "Index \(index): [\(element.elementType)] \(element.elementText)")
        }
    }

    func testParentheticals() {
        for index in [11, 26] {
            let element = script.elements[index]
            XCTAssertEqual(element.elementType, "Parenthetical", "Index \(index): [\(element.elementType)] \(element.elementText)")
        }
    }

    func testTransitions() {
        for index in [22, 31, 68, 77] {
            let element = script.elements[index]
            XCTAssertEqual(element.elementType, "Transition", "Index \(index): [\(element.elementType)] \(element.elementText)")
        }
    }

    func testActions() {
        for index in [1, 16, 30, 52] {
            let element = script.elements[index]
            XCTAssertEqual(element.elementType, "Action", "Index \(index): [\(element.elementType)] \(element.elementText)")
        }
    }

    func testCenteredElements() {
        for index in [50, 51] {
            let element = script.elements[index]
            XCTAssertTrue(element.isCentered, "Index \(index): [\(element.elementType)] \(element.elementText)")
        }
    }

    func testDualDialogue() {
        for index in [18, 20] {
            let element = script.elements[index]
            XCTAssertTrue(element.isDualDialogue, "Index \(index): [\(element.elementType)] \(element.elementText)")
        }
    }

    func testPreserveSpaces() {
        let expected = "\t*Did you know Brick and Steel are retired?*"
        XCTAssertEqual(script.elements[27].elementText, expected)
    }

    // MARK: - Title page tests

    func testTitlePage() {
        XCTAssertEqual(script.titlePage.count, 6)
    }

    func testTitle() {
        let title = script.titlePage[0]["title"]
        XCTAssertEqual(title?.count, 2)
    }
}
