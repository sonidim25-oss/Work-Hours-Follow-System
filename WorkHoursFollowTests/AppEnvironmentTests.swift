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
}
