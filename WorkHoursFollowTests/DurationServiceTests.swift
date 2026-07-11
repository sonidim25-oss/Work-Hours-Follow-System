import XCTest
@testable import WorkHoursFollow

final class DurationServiceTests: XCTestCase {
    func testConvertsTenHoursTwelveMinutes() throws {
        XCTAssertEqual(try DurationService.totalMinutes(hours: 10, minutes: 12), 612)
    }

    func testRejectsNegativeHours() {
        XCTAssertThrowsError(try DurationService.totalMinutes(hours: -1, minutes: 0)) {
            XCTAssertEqual($0 as? DurationValidationError, .negativeHours)
        }
    }

    func testRejectsMinutesOutsideRange() {
        XCTAssertThrowsError(try DurationService.totalMinutes(hours: 1, minutes: 60)) {
            XCTAssertEqual($0 as? DurationValidationError, .invalidMinutes)
        }
    }

    func testRejectsZeroDuration() {
        XCTAssertThrowsError(try DurationService.totalMinutes(hours: 0, minutes: 0)) {
            XCTAssertEqual($0 as? DurationValidationError, .zeroDuration)
        }
    }
}
