import Foundation

struct EffectiveAppSettings: Equatable, Sendable {
    let defaultHourlyRateCents: Int
    let currencyCode: String
    let anchorPayday: Date
    let payPeriodLengthDays: Int

    init(
        defaultHourlyRateCents: Int,
        currencyCode: String,
        anchorPayday: Date,
        payPeriodLengthDays: Int
    ) {
        self.defaultHourlyRateCents = defaultHourlyRateCents
        self.currencyCode = currencyCode
        self.anchorPayday = anchorPayday
        self.payPeriodLengthDays = payPeriodLengthDays
    }

    init(_ settings: AppSettings) {
        self.init(
            defaultHourlyRateCents: settings.defaultHourlyRateCents,
            currencyCode: settings.currencyCode,
            anchorPayday: settings.anchorPayday,
            payPeriodLengthDays: settings.payPeriodLengthDays
        )
    }
}

struct AppSettingsResolution {
    let effective: EffectiveAppSettings
    let needsRepair: Bool

    static func resolve(_ settings: [AppSettings], calendar: Calendar) -> Self {
        if settings.count == 1,
           let onlySettings = settings.first,
           AppEnvironment.settingsAreValid(onlySettings, calendar: calendar) {
            return Self(effective: EffectiveAppSettings(onlySettings), needsRepair: false)
        }

        return Self(
            effective: EffectiveAppSettings(AppEnvironment.defaultSettings(calendar: calendar)),
            needsRepair: true
        )
    }
}

struct AppEnvironment: Sendable {
    var calendar: Calendar
    var now: @Sendable () -> Date

    static let live = AppEnvironment(calendar: .current, now: Date.init)

#if DEBUG
    static func debugLaunchOverride(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> AppEnvironment? {
        guard arguments.contains("--ui-testing-fixed-now"),
              let dateValue = environment["UI_TEST_FIXED_NOW"],
              let timeZoneValue = environment["UI_TEST_TIME_ZONE"],
              let timeZone = TimeZone(identifier: timeZoneValue)
        else {
            return nil
        }

        let parts = dateValue.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2])
        else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        guard let fixedNow = calendar.date(
            from: DateComponents(year: year, month: month, day: day)
        ) else {
            return nil
        }

        return AppEnvironment(calendar: calendar, now: { fixedNow })
    }
#endif

    static func defaultSettings(calendar: Calendar) -> AppSettings {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        gregorian.locale = calendar.locale
        guard let anchorPayday = gregorian.date(
            from: DateComponents(year: 2026, month: 7, day: 17)
        ) else {
            preconditionFailure("The default anchor payday must be a valid calendar date")
        }

        return AppSettings(anchorPayday: anchorPayday)
    }

    static func settingsAreValid(_ settings: AppSettings, calendar: Calendar) -> Bool {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        
        let anchor = gregorian.startOfDay(for: settings.anchorPayday)
        return settings.defaultHourlyRateCents > 0
            && !settings.currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && settings.payPeriodLengthDays == 14
            && gregorian.component(.weekday, from: anchor) == 6
    }
}
