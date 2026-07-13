import XCTest
@testable import WorkHoursFollow

final class EarningsCalculatorTests: XCTestCase {
    func testRequiredExample() {
        XCTAssertEqual(try! EarningsCalculator.earningsCents(durationMinutes: 612, hourlyRateCents: 2300), 23_460)
    }

    func testRemainderBelowHalfRoundsDown() {
        XCTAssertEqual(try! EarningsCalculator.earningsCents(durationMinutes: 1, hourlyRateCents: 29), 0)
    }

    func testHalfCentRoundsUp() {
        XCTAssertEqual(try! EarningsCalculator.earningsCents(durationMinutes: 1, hourlyRateCents: 30), 1)
    }

    func testNegativeInputsThrow() {
        XCTAssertThrowsError(try EarningsCalculator.earningsCents(durationMinutes: -1, hourlyRateCents: 2300))
        XCTAssertThrowsError(try EarningsCalculator.earningsCents(durationMinutes: 612, hourlyRateCents: -1))
        XCTAssertThrowsError(try EarningsCalculator.earningsCents(durationMinutes: -10, hourlyRateCents: -20))
    }

    func testExtremeInputsThrowOverflow() {
        XCTAssertThrowsError(try EarningsCalculator.earningsCents(durationMinutes: Int.max, hourlyRateCents: Int.max))
        XCTAssertThrowsError(try EarningsCalculator.earningsCents(durationMinutes: Int.max / 2, hourlyRateCents: Int.max / 2))
    }
}
