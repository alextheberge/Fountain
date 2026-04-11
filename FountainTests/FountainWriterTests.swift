//
//  FountainWriterTests.swift
//
//  Copyright (c) 2013 Nima Yousefi & John August
//
//  MIT License — see BaseElementTests.swift
//

import XCTest
@testable import Fountain

class FountainWriterTests: XCTestCase {
    var script: FNScript!

    override func setUp() {
        super.setUp()
        script = FNScript()
    }

    func testSimpleReadWrite() {
        guard let path = FountainTestResources.path(forFixture: "Simple", extension: "fountain") else {
            XCTFail("Could not find Simple.fountain")
            return
        }
        // Use `.fast` so round-trip matches the legacy **Simple.fountain** fixture (token pipeline may re-emit `>` on `CUT TO:`).
        script.loadFile(path, parser: .fast)
        let input = (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
        let output = script.stringFromDocument()
        XCTAssertEqual(output, input, "\nElements: \(script.elements)")
    }
}
