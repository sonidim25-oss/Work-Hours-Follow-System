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

    func testSettingsResolutionUsesDefaultsWhenSettingsAreMissing() {
        let resolution = AppSettingsResolution.resolve(
            [],
            calendar: TestCalendar.toronto
        )

        XCTAssertTrue(resolution.needsRepair)
        XCTAssertEqual(resolution.effective, approvedSettingsValues)
    }

    func testSettingsResolutionUsesTheOnlyValidSettings() {
        let settings = validSettings(rate: 3_100, currencyCode: "USD")

        let resolution = AppSettingsResolution.resolve(
            [settings],
            calendar: TestCalendar.toronto
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
            calendar: TestCalendar.toronto
        )

        XCTAssertTrue(resolution.needsRepair)
        XCTAssertEqual(resolution.effective, approvedSettingsValues)
    }

    func testSettingsResolutionUsesDefaultsWhenSettingsAreDuplicated() {
        let resolution = AppSettingsResolution.resolve(
            [validSettings(rate: 3_100), validSettings(rate: 4_200)],
            calendar: TestCalendar.toronto
        )

        XCTAssertTrue(resolution.needsRepair)
        XCTAssertEqual(resolution.effective, approvedSettingsValues)
    }

    func testRepairFailureKeepsTheSameEffectiveDefaultValues() {
        let resolutionBeforeRepair = AppSettingsResolution.resolve(
            [validSettings(rate: 3_100), validSettings(rate: 4_200)],
            calendar: TestCalendar.toronto
        )

        XCTAssertEqual(resolutionBeforeRepair.effective, approvedSettingsValues)
        XCTAssertEqual(
            resolutionBeforeRepair.effective,
            AppSettingsResolution.resolve([], calendar: TestCalendar.toronto).effective
        )
    }

    private var approvedSettingsValues: EffectiveAppSettings {
        EffectiveAppSettings(
            defaultHourlyRateCents: 2_300,
            currencyCode: "CAD",
            anchorPayday: TestCalendar.date(2026, 7, 17),
            payPeriodLengthDays: 14
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
            payPeriodLengthDays: 14
        )
    }
}
