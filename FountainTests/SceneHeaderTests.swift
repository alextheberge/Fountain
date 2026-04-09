//
//  SceneHeaderTests.swift
//
//  Copyright (c) 2013 Nima Yousefi & John August
//
//  MIT License — see BaseElementTests.swift
//

import XCTest
@testable import Fountain

class SceneHeaderTests: BaseElementTests {
    override func setUp() {
        super.setUp()
        loadTestFile("SceneHeaders")
    }

    func testInt() {
        XCTAssertEqual(elementType(at: 0), "Scene Heading", error(at: 0))
    }

    func testExt() {
        XCTAssertEqual(elementType(at: 1), "Scene Heading", error(at: 1))
    }

    func testSpaceSeparators() {
        XCTAssertEqual(elementType(at: 2), "Scene Heading", error(at: 2))
        XCTAssertEqual(elementType(at: 3), "Scene Heading", error(at: 3))
    }

    func testIntExt() {
        XCTAssertEqual(elementType(at: 4), "Scene Heading", error(at: 4))
    }

    func testAbbreviatedIntExt() {
        XCTAssertEqual(elementType(at: 6),  "Scene Heading", error(at: 6))
        XCTAssertEqual(elementType(at: 7),  "Scene Heading", error(at: 7))
        XCTAssertEqual(elementType(at: 8),  "Scene Heading", error(at: 8))
    }

    func testESTHeader() {
        XCTAssertEqual(elementType(at: 11), "Scene Heading", error(at: 11))
        XCTAssertEqual(elementType(at: 12), "Scene Heading", error(at: 12))
    }

    func testSceneHeaderWithDate() {
        XCTAssertEqual(elementType(at: 13), "Scene Heading", error(at: 13))
    }

    func testForcedSceneHeader() {
        XCTAssertEqual(elementType(at: 14), "Scene Heading", error(at: 14))
    }

    func testNotAForcedSceneHeader() {
        XCTAssertNotEqual(elementType(at: 15), "Scene Heading", error(at: 15))
    }

    func testRequiresBlankLinesBeforeAndAfter() {
        XCTAssertNotEqual(elementType(at: 16), "Scene Heading", error(at: 16))
    }

    func testNeedsSeparatorAfterPrefix() {
        XCTAssertNotEqual(elementType(at: 17), "Scene Heading", error(at: 17))
    }

    func testNoCaps() {
        XCTAssertEqual(elementType(at: 18), "Scene Heading", error(at: 18))
    }
}
