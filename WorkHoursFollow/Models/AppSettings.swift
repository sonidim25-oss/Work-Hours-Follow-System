import Foundation
import SwiftData

@Model
final class AppSettings {
    var defaultHourlyRateCents: Int
    var currencyCode: String
    var anchorPayday: Date
    var payPeriodLengthDays: Int

    /// Computes a sensible default anchor payday (the next Friday)
    /// for initial app seeding on first run.
    /// The user is expected to configure their actual anchor payday in Settings.
    static func defaultAnchorPayday(now: Date, calendar: Calendar) -> Date {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        
        let startOfToday = gregorian.startOfDay(for: now)
        let currentWeekday = gregorian.component(.weekday, from: startOfToday)
        let daysToAdd = (6 - currentWeekday + 7) % 7
        return gregorian.date(byAdding: .day, value: daysToAdd, to: startOfToday)!
    }

    /// - Note: Settings are typically seeded. `anchorPayday` MUST be a Friday.
    init(
        defaultHourlyRateCents: Int = 2300,
        currencyCode: String = "CAD",
        anchorPayday: Date,
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
        
        let anchor = gregorian.startOfDay(for: date)
        guard gregorian.component(.weekday, from: anchor) == 6 else {
            throw SettingsValidationError.anchorNotFriday
        }
        self.anchorPayday = anchor
    }
}
