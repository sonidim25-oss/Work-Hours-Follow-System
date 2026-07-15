import XCTest
@testable import WorkHoursFollow

final class PeriodSummaryTests: XCTestCase {
    func testEmptySummaryUsesZeroTotals() {
        let summary = PeriodSummary(entries: [])

        XCTAssertEqual(summary.totalMinutes, 0)
        XCTAssertEqual(summary.totalEarningsCents, 0)
    }

    func testCurrentSnapshotSumsOnlyEntriesIncludedInPeriod() throws {
        let entries = [
            entry(on: 2, durationMinutes: 600, hourlyRateCents: 2_300),
            entry(on: 10, durationMinutes: 612, hourlyRateCents: 2_300),
            entry(on: 11, durationMinutes: 60, hourlyRateCents: 2_300),
            entry(on: 17, durationMinutes: 600, hourlyRateCents: 2_300),
        ]

        let snapshot = try CurrentPeriodSnapshot(
            entries: entries,
            anchorPayday: TestCalendar.date(2026, 7, 17),
            today: TestCalendar.date(2026, 7, 10),
            calendar: TestCalendar.toronto
        )

        XCTAssertEqual(snapshot.entries.map(\.workDate), [
            TestCalendar.date(2026, 7, 11),
            TestCalendar.date(2026, 7, 10),
        ])
        XCTAssertEqual(snapshot.summary.totalMinutes, 672)
        XCTAssertEqual(snapshot.summary.totalEarningsCents, 25_760)
    }

    func testSumsIndividuallyRoundedEntryEarnings() {
        let entries = [
            entry(on: 10, durationMinutes: 1, hourlyRateCents: 30),
            entry(on: 11, durationMinutes: 1, hourlyRateCents: 30),
        ]

        let summary = PeriodSummary(entries: entries)

        XCTAssertEqual(summary.totalEarningsCents, 2)
    }

    func testElapsedDaysUseInclusiveCalendarDates() throws {
        let firstDay = try CurrentPeriodSnapshot(
            entries: [],
            anchorPayday: TestCalendar.date(2026, 7, 17),
            today: TestCalendar.date(2026, 7, 3),
            calendar: TestCalendar.toronto
        )
        let lastDay = try CurrentPeriodSnapshot(
            entries: [],
            anchorPayday: TestCalendar.date(2026, 7, 17),
            today: TestCalendar.date(2026, 7, 16),
            calendar: TestCalendar.toronto
        )

        XCTAssertEqual(firstDay.elapsedDays, 1)
        XCTAssertEqual(lastDay.elapsedDays, 14)
    }

    private func entry(
        on day: Int,
        durationMinutes: Int,
        hourlyRateCents: Int
    ) -> WorkEntry {
        WorkEntry(
            workDate: TestCalendar.date(2026, 7, day),
            durationMinutes: durationMinutes,
            hourlyRateCents: hourlyRateCents,
            createdAt: .distantPast,
            updatedAt: .distantPast,
            calendar: TestCalendar.toronto
        )
    }
}
