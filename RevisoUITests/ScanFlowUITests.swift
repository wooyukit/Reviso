//
//  ScanFlowUITests.swift
//  RevisoUITests
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import XCTest

final class ScanFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    @MainActor
    func testScanView_showsInputOptions() throws {
        app.tabBars.buttons["Scan"].tap()

        XCTAssertTrue(app.buttons["Scan Document"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Choose from Library"].exists)
    }

    @MainActor
    func testScanView_showsInstructionText() throws {
        app.tabBars.buttons["Scan"].tap()

        XCTAssertTrue(app.staticTexts["Scan or pick a worksheet to erase handwritten answers"].waitForExistence(timeout: 2))
    }
}
