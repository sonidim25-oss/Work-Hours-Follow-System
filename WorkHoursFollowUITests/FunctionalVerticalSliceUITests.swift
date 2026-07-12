import XCTest

@MainActor
final class FunctionalVerticalSliceUITests: XCTestCase {
    private let fixedClockArguments = ["--ui-testing-fixed-now"]
    private let fixedClockEnvironment = [
        "UI_TEST_FIXED_NOW": "2026-07-12",
        "UI_TEST_TIME_ZONE": "America/Toronto",
    ]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOverviewShowsExpectedFixedPeriod() {
        let app = launchApp(resetData: true)
        dismissDefaultsNoticeIfNeeded(in: app)

        XCTAssertTrue(app.staticTexts["Work Hours Follow"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Jul 3, 2026 – Jul 16, 2026"].exists)
        XCTAssertTrue(app.staticTexts["Next payday: Jul 17, 2026"].exists)
        XCTAssertTrue(app.buttons["Add Work Time"].isHittable)
        capture("01-overview-live-period")

        app.buttons["Add Work Time"].tap()
        waitForEditor(title: "Add Work Time", in: app)
        assertEditorToolbarGeometry(in: app)
        capture("02-add-editor-default")
    }

    func testAddEditDuplicateDeleteAndRelaunchPersistence() {
        let app = launchApp(resetData: true)
        dismissDefaultsNoticeIfNeeded(in: app)

        XCTAssertTrue(app.staticTexts["Total Hours, 0h 0m, Total Earned, $0.00"].waitForExistence(timeout: 5))

        app.buttons["Add Work Time"].tap()
        waitForEditor(title: "Add Work Time", in: app)
        XCTAssertFalse(app.buttons["Monday, July 13"].isEnabled)
        XCTAssertFalse(app.buttons["entry-editor-save"].isEnabled)
        setEditor(dateLabel: "Friday, July 10", hours: "10", minutes: "12", in: app)
        XCTAssertTrue(app.staticTexts["$234.60"].waitForExistence(timeout: 2))
        capture("03-add-july-10-10h12m")
        app.buttons["entry-editor-save"].tap()

        XCTAssertTrue(app.staticTexts["10h 12m"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["$234.60"].exists)

        app.buttons["Add Work Time"].tap()
        setEditor(dateLabel: "Wednesday, July 8", hours: "1", minutes: "30", in: app)
        app.buttons["entry-editor-save"].tap()

        XCTAssertTrue(app.staticTexts["11h 42m"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["$269.10"].exists)
        capture("04-overview-populated")

        app.buttons["Add Work Time"].tap()
        setEditor(dateLabel: "Friday, July 10", hours: "2", minutes: "00", in: app)
        app.buttons["entry-editor-save"].tap()

        let duplicateAlert = app.alerts["Entry Already Exists"]
        XCTAssertTrue(duplicateAlert.waitForExistence(timeout: 3))
        XCTAssertTrue(duplicateAlert.buttons["Edit Existing Entry"].exists)
        XCTAssertTrue(duplicateAlert.buttons["Cancel"].exists)
        capture("05-duplicate-date-alert")
        duplicateAlert.buttons["Edit Existing Entry"].tap()

        waitForEditor(title: "Edit Work Time", in: app)
        XCTAssertEqual(app.pickerWheels.element(boundBy: 0).value as? String, "10")
        XCTAssertEqual(app.pickerWheels.element(boundBy: 1).value as? String, "12")
        app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "9")
        app.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: "00")
        app.buttons["entry-editor-save"].tap()

        XCTAssertTrue(app.staticTexts["10h 30m"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["$241.50"].exists)

        app.buttons["Entries"].tap()
        let julyTen = app.buttons["Fri, Jul 10, 9h 0m, $207.00"]
        XCTAssertTrue(julyTen.waitForExistence(timeout: 3))
        capture("06-entries-before-delete")

        requestDeletion(of: julyTen, in: app)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
        XCTAssertTrue(julyTen.exists)

        requestDeletion(of: julyTen, in: app)
        app.buttons["Delete"].tap()
        XCTAssertFalse(julyTen.waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Wed, Jul 8, 1h 30m, $34.50"].exists)

        app.terminate()
        app.launchArguments = fixedClockArguments
        app.launch()
        app.buttons["Entries"].tap()
        XCTAssertTrue(app.buttons["Wed, Jul 8, 1h 30m, $34.50"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Fri, Jul 10, 9h 0m, $207.00"].exists)
        capture("07-remaining-entry-after-relaunch")

        let remaining = app.buttons["Wed, Jul 8, 1h 30m, $34.50"]
        requestDeletion(of: remaining, in: app)
        app.buttons["Delete"].tap()
        XCTAssertFalse(remaining.waitForExistence(timeout: 2))
    }

    func testAccessibilityDynamicTypeLayoutRemainsNavigable() {
        let app = launchApp(resetData: true)
        dismissDefaultsNoticeIfNeeded(in: app)

        XCTAssertTrue(app.staticTexts["Work Hours Follow"].waitForExistence(timeout: 5))
        let addButton = app.buttons["Add Work Time"]
        let tabBar = app.tabBars.firstMatch
        for _ in 0..<3 where addButton.frame.maxY > tabBar.frame.minY - 8 {
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(addButton.isHittable)
        XCTAssertLessThanOrEqual(addButton.frame.maxY, tabBar.frame.minY - 8)
        capture("08-overview-accessibility-type-se")
        addButton.tap()

        waitForEditor(title: "Add Work Time", in: app)
        assertEditorToolbarGeometry(in: app)
        XCTAssertEqual(app.pickerWheels.count, 2)
        XCTAssertTrue(app.staticTexts["Enter a work duration greater than zero."].exists)
        XCTAssertGreaterThanOrEqual(app.buttons["entry-editor-save"].frame.width, 44)
        capture("09-editor-accessibility-type-se")
    }

    func testResetLaunchArgumentClearsPersistedEntries() {
        let app = launchApp(resetData: true)
        dismissDefaultsNoticeIfNeeded(in: app)
        XCTAssertTrue(app.staticTexts["Total Hours, 0h 0m, Total Earned, $0.00"].waitForExistence(timeout: 5))

        app.buttons["Add Work Time"].tap()
        app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "1")
        app.buttons["entry-editor-save"].tap()
        XCTAssertTrue(app.staticTexts["1h 0m"].waitForExistence(timeout: 3))

        app.terminate()
        app.launchArguments = fixedClockArguments + ["--ui-testing-reset-data"]
        app.launch()
        XCTAssertTrue(
            app.descendants(matching: .any)["ui-test-reset-complete"]
                .waitForExistence(timeout: 5)
        )
        dismissDefaultsNoticeIfNeeded(in: app)
        XCTAssertTrue(app.staticTexts["Total Hours, 0h 0m, Total Earned, $0.00"].waitForExistence(timeout: 5))
    }

    func testDuplicateEntryOffersEditOrReplaceFlow() {
        let app = launchApp(resetData: true)
        dismissDefaultsNoticeIfNeeded(in: app)

        // 1. Create initial entry
        app.buttons["Add Work Time"].tap()
        setEditor(dateLabel: "Friday, July 10", hours: "10", minutes: "12", in: app)
        app.buttons["entry-editor-save"].tap()
        XCTAssertTrue(app.staticTexts["10h 12m"].waitForExistence(timeout: 3))

        // 2. Attempt duplicate to trigger "Replace" flow
        app.buttons["Add Work Time"].tap()
        setEditor(dateLabel: "Friday, July 10", hours: "8", minutes: "00", in: app)
        app.buttons["entry-editor-save"].tap()

        let duplicateAlert = app.alerts["Entry Already Exists"]
        XCTAssertTrue(duplicateAlert.waitForExistence(timeout: 3))
        XCTAssertTrue(duplicateAlert.buttons["Edit Existing Entry"].exists)
        XCTAssertTrue(duplicateAlert.buttons["Replace"].exists)
        XCTAssertTrue(duplicateAlert.buttons["Cancel"].exists)

        // 3. Test Replace
        duplicateAlert.buttons["Replace"].tap()
        XCTAssertTrue(app.staticTexts["8h 0m"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["10h 12m"].exists)

        // 4. Attempt duplicate to trigger "Edit" flow
        app.buttons["Add Work Time"].tap()
        setEditor(dateLabel: "Friday, July 10", hours: "5", minutes: "30", in: app)
        app.buttons["entry-editor-save"].tap()

        XCTAssertTrue(duplicateAlert.waitForExistence(timeout: 3))
        duplicateAlert.buttons["Edit Existing Entry"].tap()

        // 5. Verify Edit flow populated correctly (should show 8h 0m, not 5h 30m)
        waitForEditor(title: "Edit Work Time", in: app)
        XCTAssertEqual(app.pickerWheels.element(boundBy: 0).value as? String, "8")
        XCTAssertEqual(app.pickerWheels.element(boundBy: 1).value as? String, "00")
    }

    private func launchApp(resetData: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = fixedClockArguments
            + (resetData ? ["--ui-testing-reset-data"] : [])
        app.launchEnvironment = fixedClockEnvironment
        app.launch()
        if resetData {
            XCTAssertTrue(
                app.descendants(matching: .any)["ui-test-reset-complete"]
                    .waitForExistence(timeout: 5)
            )
        }
        return app
    }

    private func waitForEditor(title: String, in app: XCUIApplication) {
        let titleElement = app.staticTexts["entry-editor-title"]
        XCTAssertTrue(titleElement.waitForExistence(timeout: 3))
        XCTAssertEqual(titleElement.label, title)
    }

    private func assertEditorToolbarGeometry(in app: XCUIApplication) {
        let windowFrame = app.windows.firstMatch.frame
        let cancel = app.buttons["entry-editor-cancel"]
        let save = app.buttons["entry-editor-save"]
        let title = app.staticTexts["entry-editor-title"]

        XCTAssertTrue(cancel.exists)
        XCTAssertTrue(cancel.isHittable)
        XCTAssertGreaterThanOrEqual(cancel.frame.width, 44)
        XCTAssertGreaterThanOrEqual(cancel.frame.height, 44)
        XCTAssertGreaterThanOrEqual(cancel.frame.minX, windowFrame.minX + 8)
        XCTAssertTrue(save.exists)
        XCTAssertTrue(save.isHittable)
        XCTAssertGreaterThanOrEqual(save.frame.width, 44)
        XCTAssertGreaterThanOrEqual(save.frame.height, 44)
        XCTAssertLessThanOrEqual(save.frame.maxX, windowFrame.maxX - 8)
        XCTAssertFalse(cancel.frame.intersects(title.frame))
        XCTAssertFalse(save.frame.intersects(title.frame))
    }

    private func dismissDefaultsNoticeIfNeeded(in app: XCUIApplication) {
        let defaultsAlert = app.alerts["Safe Defaults Restored"]
        if defaultsAlert.waitForExistence(timeout: 1) {
            defaultsAlert.buttons["OK"].tap()
        }
    }

    private func setEditor(
        dateLabel: String,
        hours: String,
        minutes: String,
        in app: XCUIApplication
    ) {
        app.buttons[dateLabel].tap()
        app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: hours)
        app.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: minutes)
    }

    private func requestDeletion(of entry: XCUIElement, in app: XCUIApplication) {
        entry.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["This work entry will be permanently removed."].waitForExistence(timeout: 2))
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
