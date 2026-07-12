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
}
