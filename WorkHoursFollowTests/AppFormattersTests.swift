import Foundation
import XCTest
@testable import WorkHoursFollow

final class AppFormattersTests: XCTestCase {
    private let locale = Locale(identifier: "en_CA")

    func testFormatsDurationAsHoursAndMinutes() {
        XCTAssertEqual(AppFormatters.duration(612), "10h 12m")
    }

    func testFormatsIntegerCentsAsCanadianCurrency() {
        XCTAssertEqual(
            AppFormatters.currency(cents: 23_460, code: "CAD", locale: locale),
            "$234.60"
        )
    }

    func testFormatsBothInclusivePayPeriodDates() {
        let period = PayPeriod(
            startDate: TestCalendar.date(2026, 7, 3),
            endDate: TestCalendar.date(2026, 7, 16),
            payday: TestCalendar.date(2026, 7, 17)
        )

        XCTAssertEqual(
            AppFormatters.periodRange(period, locale: locale),
            "Jul 3, 2026 – Jul 16, 2026"
        )
    }

    func testFormatsFullEntryDateForAccessibility() {
        XCTAssertEqual(
            AppFormatters.fullEntryDate(TestCalendar.date(2026, 7, 3), locale: locale),
            "Friday, July 3, 2026"
        )
    }
}
