//
//  SceneNumberTests.swift
//
//  Copyright (c) 2013 Nima Yousefi & John August
//
//  MIT License — see BaseElementTests.swift
//

import XCTest
@testable import Fountain

class SceneNumberTests: BaseElementTests {
    override func setUp() {
        super.setUp()
        loadTestFile("SceneNumbers")
    }

    private func sceneNumber(at index: Int) -> String? {
        return elements[index].sceneNumber
    }

    func testNumber() {
        XCTAssertEqual(elementType(at: 0),      "Scene Heading",      error(at: 0))
        XCTAssertEqual(elementText(at: 0),      "INT. HOUSE - DAY ",  error(at: 0))
        XCTAssertEqual(sceneNumber(at: 0),      "1",                  error(at: 0))
    }

    func testNumberAndLetter() {
        XCTAssertEqual(elementType(at: 1),      "Scene Heading",      error(at: 1))
        XCTAssertEqual(elementText(at: 1),      "INT. HOUSE - DAY ",  error(at: 1))
        XCTAssertEqual(sceneNumber(at: 1),      "1A",                 error(at: 1))
    }

    func testNumberAndLowercaseLetter() {
        XCTAssertEqual(elementType(at: 2),      "Scene Heading",      error(at: 2))
        XCTAssertEqual(elementText(at: 2),      "INT. HOUSE - DAY ",  error(at: 2))
        XCTAssertEqual(sceneNumber(at: 2),      "1a",                 error(at: 2))
    }

    func testLetterAndNumber() {
        XCTAssertEqual(elementType(at: 3),      "Scene Heading",      error(at: 3))
        XCTAssertEqual(elementText(at: 3),      "INT. HOUSE - DAY ",  error(at: 3))
        XCTAssertEqual(sceneNumber(at: 3),      "A1",                 error(at: 3))
    }

    func testDashes() {
        XCTAssertEqual(elementType(at: 4),      "Scene Heading",      error(at: 4))
        XCTAssertEqual(elementText(at: 4),      "INT. HOUSE - DAY ",  error(at: 4))
        XCTAssertEqual(sceneNumber(at: 4),      "I-1-A",              error(at: 4))
    }

    func testNumberWithPeriod() {
        XCTAssertEqual(elementType(at: 5),      "Scene Heading",      error(at: 5))
        XCTAssertEqual(elementText(at: 5),      "INT. HOUSE - DAY ",  error(at: 5))
        XCTAssertEqual(sceneNumber(at: 5),      "1.",                 error(at: 5))
    }

    func testSceneHeaderWithExtraInfo() {
        XCTAssertEqual(elementType(at: 6),      "Scene Heading",                           error(at: 6))
        XCTAssertEqual(elementText(at: 6),      "INT. HOUSE - DAY - FLASHBACK (1944) ",    error(at: 6))
        XCTAssertEqual(sceneNumber(at: 6),      "110A",                                    error(at: 6))
    }
}
