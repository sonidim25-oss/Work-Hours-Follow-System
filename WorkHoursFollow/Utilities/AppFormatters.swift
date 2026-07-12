import Foundation

enum AppFormatters {
    static func duration(_ minutes: Int) -> String {
        "\(minutes / 60)h \(minutes % 60)m"
    }

    static func currency(
        cents: Int,
        code: String = "CAD",
        locale: Locale = Locale(identifier: "en_CA")
    ) -> String {
        let amount = Decimal(cents) / Decimal(100)
        return amount.formatted(.currency(code: code).locale(locale))
    }

    static func periodRange(
        _ period: PayPeriod,
        calendar appCalendar: Calendar = .current,
        locale: Locale = Locale(identifier: "en_CA")
    ) -> String {
        let style = Date.FormatStyle(
            locale: locale,
            calendar: appCalendar,
            timeZone: appCalendar.timeZone
        )
            .month(.abbreviated)
            .day()
            .year()

        return "\(period.startDate.formatted(style)) – \(period.endDate.formatted(style))"
    }

    static func entryDate(
        _ date: Date,
        calendar appCalendar: Calendar = .current,
        locale: Locale = Locale(identifier: "en_CA")
    ) -> String {
        date.formatted(
            Date.FormatStyle(
                locale: locale,
                calendar: appCalendar,
                timeZone: appCalendar.timeZone
            )
                .weekday(.abbreviated)
                .month(.abbreviated)
                .day()
        )
    }

    static func shortDate(
        _ date: Date,
        calendar appCalendar: Calendar = .current,
        locale: Locale = Locale(identifier: "en_CA")
    ) -> String {
        date.formatted(
            Date.FormatStyle(
                locale: locale,
                calendar: appCalendar,
                timeZone: appCalendar.timeZone
            )
                .month(.abbreviated)
                .day()
                .year()
        )
    }

    static func fullEntryDate(
        _ date: Date,
        calendar appCalendar: Calendar = .current,
        locale: Locale = Locale(identifier: "en_CA")
    ) -> String {
        date.formatted(
            Date.FormatStyle(
                locale: locale,
                calendar: appCalendar,
                timeZone: appCalendar.timeZone
            )
                .weekday(.wide)
                .month(.wide)
                .day()
                .year()
        )
    }
}
