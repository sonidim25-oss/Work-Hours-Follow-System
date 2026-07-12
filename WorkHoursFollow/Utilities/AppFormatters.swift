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
        locale: Locale = Locale(identifier: "en_CA")
    ) -> String {
        let style = Date.FormatStyle.dateTime
            .month(.abbreviated)
            .day()
            .year()
            .locale(locale)

        return "\(period.startDate.formatted(style)) – \(period.endDate.formatted(style))"
    }

    static func entryDate(
        _ date: Date,
        locale: Locale = Locale(identifier: "en_CA")
    ) -> String {
        date.formatted(
            .dateTime
                .weekday(.abbreviated)
                .month(.abbreviated)
                .day()
                .locale(locale)
        )
    }

    static func fullEntryDate(
        _ date: Date,
        locale: Locale = Locale(identifier: "en_CA")
    ) -> String {
        date.formatted(
            .dateTime
                .weekday(.wide)
                .month(.wide)
                .day()
                .year()
                .locale(locale)
        )
    }
}
