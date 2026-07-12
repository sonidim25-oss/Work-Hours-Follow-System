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
