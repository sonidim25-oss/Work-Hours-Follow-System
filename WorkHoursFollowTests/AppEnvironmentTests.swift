import XCTest
@testable import WorkHoursFollow

final class AppEnvironmentTests: XCTestCase {
    func testDefaultSettingsMatchApprovedValues() {
        let settings = AppEnvironment.defaultSettings(calendar: TestCalendar.toronto)

        XCTAssertEqual(settings.defaultHourlyRateCents, 2300)
        XCTAssertEqual(settings.currencyCode, "CAD")
        XCTAssertEqual(settings.anchorPayday, TestCalendar.date(2026, 7, 17))
        XCTAssertEqual(settings.payPeriodLengthDays, 14)
    }

    func testOnlyDocumentedSettingsShapeIsValid() {
        let settings = AppEnvironment.defaultSettings(calendar: TestCalendar.toronto)
        XCTAssertTrue(
            AppEnvironment.settingsAreValid(
                settings,
                calendar: TestCalendar.toronto
            )
        )

        settings.anchorPayday = TestCalendar.date(2026, 7, 18)
        XCTAssertFalse(
            AppEnvironment.settingsAreValid(
                settings,
                calendar: TestCalendar.toronto
            )
        )
    }

    func testRejectsUnsupportedOrUnsafeSettingsValues() {
        let settings = AppEnvironment.defaultSettings(calendar: TestCalendar.toronto)

        settings.payPeriodLengthDays = 7
        XCTAssertFalse(AppEnvironment.settingsAreValid(settings, calendar: TestCalendar.toronto))

        settings.payPeriodLengthDays = 14
        settings.defaultHourlyRateCents = -1
        XCTAssertFalse(AppEnvironment.settingsAreValid(settings, calendar: TestCalendar.toronto))

        settings.defaultHourlyRateCents = 2_300
        settings.currencyCode = ""
        XCTAssertFalse(AppEnvironment.settingsAreValid(settings, calendar: TestCalendar.toronto))
    }
}
