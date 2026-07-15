import Foundation

enum PayPeriodCalculationError: Error, Equatable {
    case anchorIsNotFriday
    case calendarCalculationFailed
}

struct PayPeriodCalculator: Sendable {
    let calendar: Calendar

    private var fridayIndex: Int {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        // We use a known historical Friday (Jan 5, 2001) to dynamically determine the correct weekday index.
        // This is necessary because different calendar identifiers (like .iso8601 vs .gregorian) use different integer representations for weekdays (e.g. 5 vs 6).
        // Using 12:00 avoids daylight saving and boundary edge cases across timezones.
        let comps = DateComponents(year: 2001, month: 1, day: 5, hour: 12)
        let knownFriday = gregorian.date(from: comps)!
        return calendar.component(.weekday, from: knownFriday)
    }

    func period(containing date: Date, anchorPayday: Date) throws -> PayPeriod {
        let anchor = calendar.startOfDay(for: anchorPayday)
        
        guard calendar.component(.weekday, from: anchor) == fridayIndex else {
            throw PayPeriodCalculationError.anchorIsNotFriday
        }

        let day = calendar.startOfDay(for: date)
        guard let delta = calendar.dateComponents([.day], from: anchor, to: day).day else {
            throw PayPeriodCalculationError.calendarCalculationFailed
        }

        let index = delta >= 0 ? delta / 14 : -((-delta + 13) / 14)
        guard
            let start = calendar.date(byAdding: .day, value: index * 14, to: anchor),
            let end = calendar.date(byAdding: .day, value: 13, to: start),
            let payday = calendar.date(byAdding: .day, value: 14, to: start)
        else {
            throw PayPeriodCalculationError.calendarCalculationFailed
        }

        return PayPeriod(startDate: start, endDate: end, payday: payday)
    }
}
