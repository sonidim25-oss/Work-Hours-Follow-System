import Foundation

struct AppEnvironment: Sendable {
    var calendar: Calendar
    var now: @Sendable () -> Date

    static let live = AppEnvironment(calendar: .current, now: Date.init)

    static func defaultSettings(calendar: Calendar) -> AppSettings {
        guard let anchorPayday = calendar.date(
            from: DateComponents(year: 2026, month: 7, day: 17)
        ) else {
            preconditionFailure("The default anchor payday must be a valid calendar date")
        }

        return AppSettings(
            defaultHourlyRateCents: 2300,
            currencyCode: "CAD",
            anchorPayday: anchorPayday,
            payPeriodLengthDays: 14
        )
    }

    static func settingsAreValid(_ settings: AppSettings, calendar: Calendar) -> Bool {
        settings.defaultHourlyRateCents >= 0
            && !settings.currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && settings.payPeriodLengthDays == 14
            && calendar.component(.weekday, from: settings.anchorPayday) == 6
    }
}
