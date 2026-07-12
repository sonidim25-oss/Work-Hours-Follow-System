import Foundation

enum PayPeriodCalculationError: Error, Equatable {
    case anchorIsNotFriday
    case calendarCalculationFailed
}

struct PayPeriodCalculator: Sendable {
    let calendar: Calendar

    func period(containing date: Date, anchorPayday: Date) throws -> PayPeriod {
        let anchor = calendar.startOfDay(for: anchorPayday)
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        guard gregorian.component(.weekday, from: anchor) == 6 else {
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
