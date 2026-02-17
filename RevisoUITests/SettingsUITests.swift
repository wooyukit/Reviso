//
//  SettingsUITests.swift
//  RevisoUITests
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

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
    func testSettingsView_showsProviderPicker() throws {
        XCTAssertTrue(app.buttons["Claude"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["OpenAI"].exists)
        XCTAssertTrue(app.buttons["Gemini"].exists)
    }

    @MainActor
    func testSettingsView_showsAPIKeyField() throws {
        XCTAssertTrue(app.secureTextFields["Enter API Key"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testSettingsView_saveButtonDisabledWhenEmpty() throws {
        let saveButton = app.buttons["Save API Key"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
        XCTAssertFalse(saveButton.isEnabled)
    }

    @MainActor
    func testSettingsView_saveButtonEnabledWithInput() throws {
        let apiKeyField = app.secureTextFields["Enter API Key"]
        XCTAssertTrue(apiKeyField.waitForExistence(timeout: 2))

        apiKeyField.tap()
        apiKeyField.typeText("sk-test-key-123")

        let saveButton = app.buttons["Save API Key"]
        XCTAssertTrue(saveButton.isEnabled)
    }

    @MainActor
    func testSettingsView_switchProvider() throws {
        let openAIButton = app.buttons["OpenAI"]
        XCTAssertTrue(openAIButton.waitForExistence(timeout: 2))

        openAIButton.tap()

        // API key field should still be visible after switching
        XCTAssertTrue(app.secureTextFields["Enter API Key"].exists)
    }

    @MainActor
    func testSettingsView_saveAndDeleteAPIKey() throws {
        let apiKeyField = app.secureTextFields["Enter API Key"]
        XCTAssertTrue(apiKeyField.waitForExistence(timeout: 2))

        apiKeyField.tap()
        apiKeyField.typeText("sk-test-ui-key")

        app.buttons["Save API Key"].tap()

        // After saving, should show "API Key Saved" and "Remove" button
        XCTAssertTrue(app.staticTexts["API Key Saved"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Remove"].exists)

        // Delete the key
        app.buttons["Remove"].tap()

        // Should show the input field again
        XCTAssertTrue(app.secureTextFields["Enter API Key"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testSettingsView_showsAboutSection() throws {
        app.swipeUp()
        // LabeledContent renders as "Version, 1.0.0" in accessibility
        let versionLabel = app.staticTexts["Version"]
        XCTAssertTrue(versionLabel.waitForExistence(timeout: 3))
    }
}
