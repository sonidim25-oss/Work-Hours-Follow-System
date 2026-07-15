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

    // MARK: - RoundingStrategy Tests

    func testRoundingStrategyRoundsDownBelowThreshold() {
        XCTAssertEqual(EarningsCalculator.RoundingStrategy.nearestCent(quotient: 10, remainder: 29, divisor: 60), 10)
        XCTAssertEqual(EarningsCalculator.RoundingStrategy.nearestCent(quotient: 10, remainder: 0, divisor: 60), 10)
    }

    func testRoundingStrategyRoundsUpAtOrAboveThreshold() {
        XCTAssertEqual(EarningsCalculator.RoundingStrategy.nearestCent(quotient: 10, remainder: 30, divisor: 60), 11)
        XCTAssertEqual(EarningsCalculator.RoundingStrategy.nearestCent(quotient: 10, remainder: 59, divisor: 60), 11)
    }
}
