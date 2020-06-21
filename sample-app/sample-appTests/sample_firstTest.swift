//
//  sample_firstTest.swift
//  sample-appTests
//
//  Created by Alexey Alter Pesotskiy on 20/06/2020.
//  Copyright © 2020 alteral. All rights reserved.
//

import XCTest
@testable import sample_app

class sample_firstTest: XCTestCase {

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
