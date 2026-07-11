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
}
