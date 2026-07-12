import Foundation
import SwiftData

@Model
final class AppSettings {
    var defaultHourlyRateCents: Int
    var currencyCode: String
    var anchorPayday: Date
    var payPeriodLengthDays: Int

    /// A static, hardcoded default Friday used only for initial app seeding on first run.
    /// The user is expected to configure their actual anchor payday in Settings.
    static var defaultAnchorPayday: Date {
        var gregorian = Calendar(identifier: .gregorian)
        return gregorian.date(from: DateComponents(year: 2026, month: 7, day: 17))!
    }

    static var defaults: AppSettings {
        AppSettings()
    }

    /// - Note: Settings are typically seeded. `anchorPayday` MUST be a Friday.
    init(
        defaultHourlyRateCents: Int = 2300,
        currencyCode: String = "CAD",
        anchorPayday: Date = AppSettings.defaultAnchorPayday,
        payPeriodLengthDays: Int = 14
    ) {
        self.defaultHourlyRateCents = defaultHourlyRateCents
        self.currencyCode = currencyCode
        self.anchorPayday = anchorPayday
        self.payPeriodLengthDays = payPeriodLengthDays
    }

    enum SettingsValidationError: LocalizedError {
        case anchorNotFriday
        
        var errorDescription: String? {
            switch self {
            case .anchorNotFriday:
                return "The anchor payday must be a Friday."
            }
        }
    }

    func updateAnchorPayday(to date: Date, calendar: Calendar) throws {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        guard gregorian.component(.weekday, from: date) == 6 else {
            throw SettingsValidationError.anchorNotFriday
        }
        self.anchorPayday = date
    }
}
