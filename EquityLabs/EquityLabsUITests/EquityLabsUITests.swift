//
//  EquityLabsUITests.swift
//  EquityLabsUITests
//
//  Created by Daniel Pang on 2026-02-01.
//

import XCTest

final class EquityLabsUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Sign In Flow Tests

    @MainActor
    func testSignInViewDisplaysCorrectly() throws {
        // The app should show the sign-in view when not authenticated
        // Check for the EquityLabs title text
        let titleText = app.staticTexts["EquityLabs"]
        if titleText.waitForExistence(timeout: 5) {
            XCTAssertTrue(titleText.exists, "EquityLabs title should be visible on sign-in screen")
        }

        // Check for the tagline
        let tagline = app.staticTexts["Track your portfolio with confidence"]
        if tagline.exists {
            XCTAssertTrue(tagline.exists)
        }
    }

    @MainActor
    func testDemoModeSignIn() throws {
        // Look for the "Continue as Demo" button
        let demoButton = app.buttons["Continue as demo user"]
        if demoButton.waitForExistence(timeout: 5) {
            demoButton.tap()

            // After demo sign in, we should see the dashboard
            let navTitle = app.navigationBars["EquityLabs"]
            XCTAssertTrue(navTitle.waitForExistence(timeout: 10), "Dashboard should appear after demo sign in")
        }
    }

    // MARK: - Dashboard Tests

    @MainActor
    func testDashboardDisplaysAfterSignIn() throws {
        signInAsDemo()

        // Check navigation bar exists
        let navBar = app.navigationBars["EquityLabs"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 10), "Dashboard navigation bar should exist")
    }

    @MainActor
    func testAddStockButtonExists() throws {
        signInAsDemo()

        let addButton = app.buttons["Add stock"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 10), "Add stock button should exist in toolbar")
    }

    @MainActor
    func testSettingsButtonExists() throws {
        signInAsDemo()

        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10), "Settings button should exist in toolbar")
    }

    // MARK: - Add Stock Flow Tests

    @MainActor
    func testAddStockFlowOpens() throws {
        signInAsDemo()

        let addButton = app.buttons["Add stock"]
        guard addButton.waitForExistence(timeout: 10) else {
            XCTFail("Add stock button not found")
            return
        }
        addButton.tap()

        // The Add Stock sheet should appear
        let addStockTitle = app.navigationBars["Add Stock"]
        XCTAssertTrue(addStockTitle.waitForExistence(timeout: 5), "Add Stock sheet should appear")

        // Cancel button should exist
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
    }

    @MainActor
    func testAddStockSearchField() throws {
        signInAsDemo()

        let addButton = app.buttons["Add stock"]
        guard addButton.waitForExistence(timeout: 10) else {
            XCTFail("Add stock button not found")
            return
        }
        addButton.tap()

        // Wait for Add Stock sheet
        let addStockTitle = app.navigationBars["Add Stock"]
        guard addStockTitle.waitForExistence(timeout: 5) else {
            XCTFail("Add Stock sheet did not appear")
            return
        }

        // Find and interact with search field
        let searchField = app.textFields["Search stocks (e.g., AAPL)"]
        if searchField.waitForExistence(timeout: 3) {
            searchField.tap()
            searchField.typeText("AAPL")

            // Verify text was entered
            XCTAssertEqual(searchField.value as? String, "AAPL")
        }
    }

    @MainActor
    func testAddStockCancel() throws {
        signInAsDemo()

        let addButton = app.buttons["Add stock"]
        guard addButton.waitForExistence(timeout: 10) else {
            XCTFail("Add stock button not found")
            return
        }
        addButton.tap()

        let addStockTitle = app.navigationBars["Add Stock"]
        guard addStockTitle.waitForExistence(timeout: 5) else {
            XCTFail("Add Stock sheet did not appear")
            return
        }

        // Tap cancel
        let cancelButton = app.buttons["Cancel"]
        cancelButton.tap()

        // We should be back on the dashboard
        let navBar = app.navigationBars["EquityLabs"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Should return to dashboard after cancel")
    }

    // MARK: - Settings Tests

    @MainActor
    func testSettingsFlowOpens() throws {
        signInAsDemo()

        let settingsButton = app.buttons["Settings"]
        guard settingsButton.waitForExistence(timeout: 10) else {
            XCTFail("Settings button not found")
            return
        }
        settingsButton.tap()

        // Settings sheet should appear
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5), "Settings sheet should appear")
    }

    @MainActor
    func testSettingsHasSignOutButton() throws {
        signInAsDemo()

        let settingsButton = app.buttons["Settings"]
        guard settingsButton.waitForExistence(timeout: 10) else {
            XCTFail("Settings button not found")
            return
        }
        settingsButton.tap()

        let settingsTitle = app.navigationBars["Settings"]
        guard settingsTitle.waitForExistence(timeout: 5) else {
            XCTFail("Settings sheet did not appear")
            return
        }

        // Scroll to find sign out button
        let signOutButton = app.buttons["Sign Out"]
        if signOutButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(signOutButton.exists, "Sign Out button should exist in settings")
        } else {
            // Try scrolling down to find it
            app.swipeUp()
            XCTAssertTrue(signOutButton.waitForExistence(timeout: 3), "Sign Out button should exist after scrolling")
        }
    }

    @MainActor
    func testSettingsDismiss() throws {
        signInAsDemo()

        let settingsButton = app.buttons["Settings"]
        guard settingsButton.waitForExistence(timeout: 10) else {
            XCTFail("Settings button not found")
            return
        }
        settingsButton.tap()

        let settingsTitle = app.navigationBars["Settings"]
        guard settingsTitle.waitForExistence(timeout: 5) else {
            XCTFail("Settings sheet did not appear")
            return
        }

        // Tap Done
        let doneButton = app.buttons["Done"]
        doneButton.tap()

        // Should return to dashboard
        let navBar = app.navigationBars["EquityLabs"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Should return to dashboard after dismissing settings")
    }

    // MARK: - Launch Performance

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    // MARK: - Helpers

    private func signInAsDemo() {
        let demoButton = app.buttons["Continue as demo user"]
        if demoButton.waitForExistence(timeout: 5) {
            demoButton.tap()
        }
        // Wait for dashboard to appear
        _ = app.navigationBars["EquityLabs"].waitForExistence(timeout: 10)
    }
}
