//
//  RevisoUITests.swift
//  RevisoUITests
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import XCTest

final class RevisoUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Tab Navigation

    @MainActor
    func testTabBar_showsThreeTabs() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists)

        XCTAssertTrue(tabBar.buttons["Worksheets"].exists)
        XCTAssertTrue(tabBar.buttons["Scan"].exists)
        XCTAssertTrue(tabBar.buttons["Settings"].exists)
    }

    @MainActor
    func testTabBar_defaultsToWorksheetsTab() throws {
        XCTAssertTrue(app.navigationBars["My Worksheets"].exists)
    }

    @MainActor
    func testTabBar_switchToScanTab() throws {
        app.tabBars.buttons["Scan"].tap()
        XCTAssertTrue(app.navigationBars["Scan Worksheet"].exists)
    }

    @MainActor
    func testTabBar_switchToSettingsTab() throws {
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
    }

    // MARK: - Worksheets Tab

    @MainActor
    func testWorksheetsTab_showsEmptyState() throws {
        XCTAssertTrue(app.staticTexts["No Worksheets Yet"].exists)
    }
}
