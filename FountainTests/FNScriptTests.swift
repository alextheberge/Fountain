//
//  FNScriptTests.swift
//
//  Copyright (c) 2012 Nima Yousefi & John August
//
//  MIT License — see BaseElementTests.swift
//

import XCTest
@testable import Fountain

class FNScriptTests: XCTestCase {
    var script: FNScript!

    override func setUp() {
        super.setUp()
        script = FNScript()
    }

    func testInitFromString() {
        let testScript = FNScript(string: "FADE IN:")
        XCTAssertNotNil(testScript)
    }

    func testLoadFile() {
        guard let path = Bundle(for: type(of: self)).path(forResource: "Big Fish", ofType: "fountain") else {
            XCTFail("Could not find Big Fish.fountain")
            return
        }
        script.loadFile(path)
        XCTAssertNotNil(script)
    }

    func testLoadString() {
        script.loadString("FADE IN:")
        XCTAssertNotNil(script)
    }

    func testStringFromTitlePage() {
        let expected = "Title: A Simple Script\nAuthor: Nima Yousefi\nDraft date: 2/1/2012\n"
        guard let path = Bundle(for: type(of: self)).path(forResource: "Simple", ofType: "fountain") else {
            XCTFail("Could not find Simple.fountain")
            return
        }
        script.loadFile(path)
        XCTAssertEqual(script.stringFromTitlePage(), expected)
    }

    func testElementDescription() {
        let input = "FADE IN:\n\nINT. HOUSE - DAY\n\nMAN\nI'm in the house.\n\n> The end. <"
        script.loadString(input)
        let elements = script.elements

        XCTAssertEqual(elements[0].description, "Action: FADE IN:")
        XCTAssertEqual(elements[1].description, "Scene Heading: INT. HOUSE - DAY")
        XCTAssertEqual(elements[2].description, "Character: MAN")
        XCTAssertEqual(elements[3].description, "Dialogue: I'm in the house.")
        XCTAssertEqual(elements[4].description, "Action (centered): The end.")
    }

    func testScriptDescription() {
        let input = "FADE IN:\n\nINT. HOUSE - DAY\n\nMAN\nI'm in the house.\n\n> The end. <"
        script.loadString(input)
        XCTAssertEqual(script.description, input)
    }

    func testTitlesWithoutColons() {
        let input = "Title:\n\tI KNOW WHAT YOU DID\n\tLAST SUMMER"
        script.loadString(input)
        XCTAssertEqual(script.description, input)
    }

    func testTitlesWithColons() {
        let input = "Title:\n\tI KNOW WHAT YOU DID:\n\tLAST SUMMER"
        script.loadString(input)
        XCTAssertEqual(script.description, input)
    }
}
