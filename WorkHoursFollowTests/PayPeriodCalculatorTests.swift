import XCTest
@testable import WorkHoursFollow

final class PayPeriodCalculatorTests: XCTestCase {
    private let calculator = PayPeriodCalculator(calendar: TestCalendar.toronto)
    private let anchor = TestCalendar.date(2026, 7, 17)

    func testJulyTenFallsInJulyThreeThroughSixteenPeriod() throws {
        let period = try calculator.period(
            containing: TestCalendar.date(2026, 7, 10),
            anchorPayday: anchor
        )

        XCTAssertEqual(period.startDate, TestCalendar.date(2026, 7, 3))
        XCTAssertEqual(period.endDate, TestCalendar.date(2026, 7, 16))
        XCTAssertEqual(period.payday, anchor)
    }

    func testJulySixteenRemainsInEndingPeriod() throws {
        let period = try calculator.period(
            containing: TestCalendar.date(2026, 7, 16),
            anchorPayday: anchor
        )

        XCTAssertEqual(period.startDate, TestCalendar.date(2026, 7, 3))
    }

    func testJulySeventeenStartsNextPeriod() throws {
        let period = try calculator.period(containing: anchor, anchorPayday: anchor)

        XCTAssertEqual(period.startDate, anchor)
        XCTAssertEqual(period.endDate, TestCalendar.date(2026, 7, 30))
        XCTAssertEqual(period.payday, TestCalendar.date(2026, 7, 31))
    }

    func testWorksAcrossYearBoundary() throws {
        let period = try calculator.period(
            containing: TestCalendar.date(2027, 1, 1),
            anchorPayday: anchor
        )

        XCTAssertTrue(
            period.contains(TestCalendar.date(2027, 1, 1), calendar: TestCalendar.toronto)
        )
    }

    func testRejectsNonFridayAnchor() {
        XCTAssertThrowsError(
            try calculator.period(
                containing: anchor,
                anchorPayday: TestCalendar.date(2026, 7, 16)
            )
        ) {
            XCTAssertEqual($0 as? PayPeriodCalculationError, .anchorIsNotFriday)
        }
    }

    func testUsesCalendarDaysAcrossDaylightSaving() throws {
        let anchor = TestCalendar.date(2026, 3, 6)
        let period = try calculator.period(
            containing: TestCalendar.date(2026, 3, 15),
            anchorPayday: anchor
        )

        XCTAssertEqual(period.startDate, anchor)
        XCTAssertEqual(period.endDate, TestCalendar.date(2026, 3, 19))
    }

    func testNonGregorianCalendarAnchorValidation() throws {
        var islamicCalendar = Calendar(identifier: .islamic)
        islamicCalendar.timeZone = TestCalendar.toronto.timeZone
        let islamicCalculator = PayPeriodCalculator(calendar: islamicCalendar)
        
        // July 17, 2026 is Friday.
        let anchorFriday = TestCalendar.date(2026, 7, 17)
        XCTAssertNoThrow(
            try islamicCalculator.period(
                containing: anchorFriday,
                anchorPayday: anchorFriday
            )
        )
    }
    
    func testISO8601CalendarValidation() throws {
        var isoCalendar = Calendar(identifier: .iso8601)
        isoCalendar.timeZone = TestCalendar.toronto.timeZone
        let isoCalculator = PayPeriodCalculator(calendar: isoCalendar)
        
        // In ISO8601, Friday is index 5, not 6.
        let anchorFriday = TestCalendar.date(2026, 7, 17)
        XCTAssertNoThrow(
            try isoCalculator.period(
                containing: anchorFriday,
                anchorPayday: anchorFriday
            )
        )
        
        let anchorThursday = TestCalendar.date(2026, 7, 16)
        XCTAssertThrowsError(
            try isoCalculator.period(
                containing: anchorFriday,
                anchorPayday: anchorThursday
            )
        ) {
            XCTAssertEqual($0 as? PayPeriodCalculationError, .anchorIsNotFriday)
        }
    }

    func testDifferentTimeZonesDoNotBreakCalculation() throws {
        var tokyoCalendar = Calendar(identifier: .gregorian)
        tokyoCalendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let tokyoCalculator = PayPeriodCalculator(calendar: tokyoCalendar)
        
        // Friday in Tokyo
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 7
        comps.day = 17
        comps.hour = 12
        let anchorFridayTokyo = tokyoCalendar.date(from: comps)!
        
        XCTAssertNoThrow(
            try tokyoCalculator.period(
                containing: anchorFridayTokyo,
                anchorPayday: anchorFridayTokyo
            )
        )
    }
}
