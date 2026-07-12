import Foundation

struct PayPeriod: Equatable, Sendable {
    let startDate: Date
    let endDate: Date
    let payday: Date

    func contains(_ date: Date, calendar: Calendar) -> Bool {
        let day = calendar.startOfDay(for: date)
        return day >= startDate && day <= endDate
    }
}
