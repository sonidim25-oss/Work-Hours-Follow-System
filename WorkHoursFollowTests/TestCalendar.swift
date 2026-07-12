import Foundation

enum TestCalendar {
    static var toronto: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        guard let timeZone = TimeZone(identifier: "America/Toronto") else {
            preconditionFailure("America/Toronto must be available in the test environment")
        }
        calendar.timeZone = timeZone
        calendar.locale = Locale(identifier: "en_CA")
        return calendar
    }

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        guard let date = toronto.date(from: DateComponents(year: year, month: month, day: day)) else {
            preconditionFailure("Invalid test date: \(year)-\(month)-\(day)")
        }
        return date
    }
}
