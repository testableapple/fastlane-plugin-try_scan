//
//  sample_appSuccessfulUITests.swift
//  sample-appSuccessfulUITests
//
//  Created by Alexey Alter Pesotskiy on 20/06/2020.
//  Copyright © 2020 alteral. All rights reserved.
//

import XCTest

class sample_appSuccessfulUITests: XCTestCase {

    override func setUp() {
        XCUIApplication().launch()
    }

    func test() {
        XCTAssertTrue(true)
    }
}
