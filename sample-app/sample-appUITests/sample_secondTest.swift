//
//  sample_secondTest.swift
//  sample-appUITests
//
//  Created by Alexey Alter Pesotskiy on 20/06/2020.
//  Copyright © 2020 alteral. All rights reserved.
//

import XCTest

class sample_secondTest: XCTestCase {

    override func setUp() {
        XCUIApplication().launch()
    }

    func test1() {
        XCTAssertTrue(3 > Int.random(in: 1..<4))
    }

    func test2() {
        XCTAssertTrue(3 > Int.random(in: 1..<4))
    }

    func test3() {
        XCTAssertTrue(3 > Int.random(in: 1..<4))
    }

}
