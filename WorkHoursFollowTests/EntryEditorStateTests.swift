import XCTest
@testable import WorkHoursFollow

final class EntryEditorStateTests: XCTestCase {
    private let calendar = TestCalendar.toronto
    private let now = TestCalendar.date(2026, 7, 11)

    func testZeroDurationDisablesSaveAndExplainsWhy() {
        let state = EntryEditorState(
            date: now,
            hours: 0,
            minutes: 0,
            hourlyRateCents: 2_300
        )

        XCTAssertFalse(state.canSave(now: now, calendar: calendar))
        XCTAssertEqual(state.validationMessage(now: now, calendar: calendar), "Enter a work duration greater than zero.")
    }

    func testTenHoursTwelveMinutesPreviewsExpectedEarnings() {
        let state = EntryEditorState(
            date: now,
            hours: 10,
            minutes: 12,
            hourlyRateCents: 2_300
        )

        XCTAssertEqual(state.durationMinutes, 612)
        XCTAssertEqual(state.earningsCents, 23_460)
        XCTAssertTrue(state.canSave(now: now, calendar: calendar))
        XCTAssertNil(state.validationMessage(now: now, calendar: calendar))
    }

    func testFutureDateDisablesSaveAndExplainsWhy() throws {
        let futureDate = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: now))
        let state = EntryEditorState(
            date: futureDate,
            hours: 1,
            minutes: 0,
            hourlyRateCents: 2_300
        )

        XCTAssertFalse(state.canSave(now: now, calendar: calendar))
        XCTAssertEqual(state.validationMessage(now: now, calendar: calendar), "Choose today or an earlier date.")
    }

    func testEditingInitializesFromEntryAndRetainsItsRate() {
        let entry = WorkEntry(
            workDate: TestCalendar.date(2026, 7, 10),
            durationMinutes: 612,
            hourlyRateCents: 2_550,
            createdAt: now,
            updatedAt: now,
            calendar: calendar
        )

        let state = EntryEditorState(entry: entry)

        XCTAssertEqual(state.date, entry.workDate)
        XCTAssertEqual(state.hours, 10)
        XCTAssertEqual(state.minutes, 12)
        XCTAssertEqual(state.hourlyRateCents, 2_550)
    }
}
