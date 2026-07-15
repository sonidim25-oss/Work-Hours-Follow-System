import XCTest
@testable import WorkHoursFollow

final class AppEnvironmentTests: XCTestCase {
#if DEBUG
    func testDebugFixedClockUsesRequestedTorontoCalendarDate() throws {
        let environment = try XCTUnwrap(
            AppEnvironment.debugLaunchOverride(
                arguments: ["WorkHoursFollow", "--ui-testing-fixed-now"],
                environment: [
                    "UI_TEST_FIXED_NOW": "2026-07-12",
                    "UI_TEST_TIME_ZONE": "America/Toronto",
                ]
            )
        )

        XCTAssertEqual(environment.calendar.identifier, .gregorian)
        XCTAssertEqual(environment.calendar.timeZone.identifier, "America/Toronto")
        XCTAssertEqual(
            environment.calendar.dateComponents([.year, .month, .day], from: environment.now()),
            DateComponents(year: 2026, month: 7, day: 12)
        )
    }

    func testDebugFixedClockRequiresItsLaunchArgument() {
        XCTAssertNil(
            AppEnvironment.debugLaunchOverride(
                arguments: ["WorkHoursFollow"],
                environment: [
                    "UI_TEST_FIXED_NOW": "2026-07-12",
                    "UI_TEST_TIME_ZONE": "America/Toronto",
                ]
            )
        )
    }
#endif

    func testDefaultSettingsMatchApprovedValues() {
        let settings = AppEnvironment.defaultSettings(calendar: TestCalendar.toronto, now: TestCalendar.date(2026, 7, 17))

        XCTAssertEqual(settings.defaultHourlyRateCents, 2300)
        XCTAssertEqual(settings.currencyCode, "CAD")
        XCTAssertEqual(settings.anchorPayday, TestCalendar.date(2026, 7, 17))
        XCTAssertEqual(settings.payPeriodLengthDays, 14)
    }

    func testOnlyDocumentedSettingsShapeIsValid() {
        let settings = AppEnvironment.defaultSettings(calendar: TestCalendar.toronto, now: TestCalendar.date(2026, 7, 17))
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

    func testDefaultAnchorUsesGregorianComponentsInInjectedTimeZone() {
        var preferredCalendar = Calendar(identifier: .buddhist)
        preferredCalendar.timeZone = TestCalendar.toronto.timeZone
        let settings = AppEnvironment.defaultSettings(calendar: preferredCalendar, now: TestCalendar.date(2026, 7, 17))
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = preferredCalendar.timeZone

        XCTAssertEqual(
            gregorian.dateComponents([.year, .month, .day], from: settings.anchorPayday),
            DateComponents(year: 2026, month: 7, day: 17)
        )

        let resolution = AppSettingsResolution.resolve(
            [settings],
            calendar: preferredCalendar,
            now: TestCalendar.date(2026, 7, 17)
        )
        XCTAssertFalse(resolution.needsRepair)
        XCTAssertEqual(resolution.effective.anchorPayday, settings.anchorPayday)
    }

    func testRejectsUnsupportedOrUnsafeSettingsValues() {
        let settings = AppEnvironment.defaultSettings(calendar: TestCalendar.toronto, now: TestCalendar.date(2026, 7, 17))

        settings.payPeriodLengthDays = 7
        XCTAssertFalse(AppEnvironment.settingsAreValid(settings, calendar: TestCalendar.toronto))

        settings.payPeriodLengthDays = 14
        settings.defaultHourlyRateCents = -1
        XCTAssertFalse(AppEnvironment.settingsAreValid(settings, calendar: TestCalendar.toronto))

        settings.defaultHourlyRateCents = 0
        XCTAssertFalse(AppEnvironment.settingsAreValid(settings, calendar: TestCalendar.toronto))

        settings.defaultHourlyRateCents = 2_300
        settings.currencyCode = ""
        XCTAssertFalse(AppEnvironment.settingsAreValid(settings, calendar: TestCalendar.toronto))
    }

    func testSettingsResolutionUsesDefaultsWhenSettingsAreMissing() {
        let resolution = AppSettingsResolution.resolve(
            [],
            calendar: TestCalendar.toronto,
            now: TestCalendar.date(2026, 7, 17)
        )

        XCTAssertTrue(resolution.needsRepair)
        XCTAssertEqual(resolution.effective, approvedSettingsValues)
    }

    func testSettingsResolutionUsesTheOnlyValidSettings() {
        let settings = validSettings(rate: 3_100, currencyCode: "USD")

        let resolution = AppSettingsResolution.resolve(
            [settings],
            calendar: TestCalendar.toronto,
            now: TestCalendar.date(2026, 7, 17)
        )

        XCTAssertFalse(resolution.needsRepair)
        XCTAssertEqual(resolution.effective.defaultHourlyRateCents, 3_100)
        XCTAssertEqual(resolution.effective.currencyCode, "USD")
        XCTAssertEqual(resolution.effective.anchorPayday, TestCalendar.date(2026, 7, 17))
        XCTAssertEqual(resolution.effective.payPeriodLengthDays, 14)
    }

    func testSettingsResolutionUsesDefaultsWhenTheOnlySettingsAreInvalid() {
        let invalidSettings = validSettings(rate: -1)

        let resolution = AppSettingsResolution.resolve(
            [invalidSettings],
            calendar: TestCalendar.toronto,
            now: TestCalendar.date(2026, 7, 17)
        )

        XCTAssertTrue(resolution.needsRepair)
        XCTAssertEqual(resolution.effective, approvedSettingsValues)
    }

    func testSettingsResolutionUsesDefaultsWhenSettingsAreDuplicated() {
        let resolution = AppSettingsResolution.resolve(
            [validSettings(rate: 3_100), validSettings(rate: 4_200)],
            calendar: TestCalendar.toronto,
            now: TestCalendar.date(2026, 7, 17)
        )

        XCTAssertTrue(resolution.needsRepair)
        XCTAssertEqual(resolution.effective, approvedSettingsValues)
    }

    func testRepairFailureKeepsTheSameEffectiveDefaultValues() {
        let resolutionBeforeRepair = AppSettingsResolution.resolve(
            [validSettings(rate: 3_100), validSettings(rate: 4_200)],
            calendar: TestCalendar.toronto,
            now: TestCalendar.date(2026, 7, 17)
        )

        XCTAssertEqual(resolutionBeforeRepair.effective, approvedSettingsValues)
        XCTAssertEqual(
            resolutionBeforeRepair.effective,
            AppSettingsResolution.resolve([], calendar: TestCalendar.toronto, now: TestCalendar.date(2026, 7, 17)).effective
        )
    }

    private var approvedSettingsValues: EffectiveAppSettings {
        EffectiveAppSettings(
            defaultHourlyRateCents: 2_300,
            currencyCode: "CAD",
            anchorPayday: TestCalendar.date(2026, 7, 17),
            payPeriodLengthDays: 14,
            targetEarningsCents: nil
        )
    }

    private func validSettings(
        rate: Int,
        currencyCode: String = "CAD"
    ) -> AppSettings {
        AppSettings(
            defaultHourlyRateCents: rate,
            currencyCode: currencyCode,
            anchorPayday: TestCalendar.date(2026, 7, 17),
            payPeriodLengthDays: 14,
            targetEarningsCents: nil
        )
    }
}
