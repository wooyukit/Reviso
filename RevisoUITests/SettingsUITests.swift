import XCTest

final class SettingsUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Settings"].tap()
    }

    @MainActor
    func testSettingsTab_showsNavigationTitle() throws {
        XCTAssertTrue(app.navigationBars["Settings"].exists)
    }

    @MainActor
    func testSettingsTab_showsLanguageSection() throws {
        XCTAssertTrue(app.staticTexts["Language"].exists)
    }

    @MainActor
    func testSettingsTab_showsAboutSection() throws {
        XCTAssertTrue(app.staticTexts["About"].exists)
    }

    @MainActor
    func testSettingsTab_showsVersion() throws {
        XCTAssertTrue(app.staticTexts["Version"].exists)
    }
}
