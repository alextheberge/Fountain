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
        guard let path = Bundle(for: type(of: self)).path(forResource: "Simple", ofType: "fountain") else {
            XCTFail("Could not find Simple.fountain")
            return
        }
        script.loadFile(path)
        let input  = (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
        let output = script.stringFromDocument()
        XCTAssertEqual(output, input, "\nElements: \(script.elements)")
    }
}
