import XCTest
@testable import WorkHoursFollow

final class EarningsCalculatorTests: XCTestCase {
    func testRequiredExample() {
        XCTAssertEqual(EarningsCalculator.earningsCents(durationMinutes: 612, hourlyRateCents: 2300), 23_460)
    }

    func testRemainderBelowHalfRoundsDown() {
        XCTAssertEqual(EarningsCalculator.earningsCents(durationMinutes: 1, hourlyRateCents: 29), 0)
    }

    func testHalfCentRoundsUp() {
        XCTAssertEqual(EarningsCalculator.earningsCents(durationMinutes: 1, hourlyRateCents: 30), 1)
    }

    func testNegativeInputsReturnZero() {
        XCTAssertEqual(EarningsCalculator.earningsCents(durationMinutes: -1, hourlyRateCents: 2300), 0)
        XCTAssertEqual(EarningsCalculator.earningsCents(durationMinutes: 612, hourlyRateCents: -1), 0)
        XCTAssertEqual(EarningsCalculator.earningsCents(durationMinutes: -10, hourlyRateCents: -20), 0)
    }

    func testExtremeInputsClampToIntMax() {
        XCTAssertEqual(EarningsCalculator.earningsCents(durationMinutes: Int.max, hourlyRateCents: Int.max), Int.max)
        XCTAssertEqual(EarningsCalculator.earningsCents(durationMinutes: Int.max / 2, hourlyRateCents: Int.max / 2), Int.max)
    }
}
