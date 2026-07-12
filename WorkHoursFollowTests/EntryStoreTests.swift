import SwiftData
import XCTest
@testable import WorkHoursFollow

@MainActor
final class EntryStoreTests: XCTestCase {
    func testCreateNormalizesDateAndSnapshotsGivenRate() throws {
        let (_, store) = try makeStore()
        let calendar = TestCalendar.toronto
        let date = try XCTUnwrap(
            calendar.date(byAdding: .hour, value: 14, to: TestCalendar.date(2026, 7, 10))
        )
        let now = TestCalendar.date(2026, 7, 11)

        let entry = try store.create(
            date: date,
            durationMinutes: 75,
            hourlyRateCents: 2_300,
            now: now
        )

        XCTAssertEqual(entry.workDate, TestCalendar.date(2026, 7, 10))
        XCTAssertEqual(entry.durationMinutes, 75)
        XCTAssertEqual(entry.hourlyRateCents, 2_300)
        XCTAssertEqual(entry.createdAt, now)
        XCTAssertEqual(entry.updatedAt, now)
        XCTAssertEqual(try store.allEntries().map(\.id), [entry.id])
    }

    func testCreateRejectsFutureDateWithoutInserting() throws {
        let (_, store) = try makeStore()

        XCTAssertThrowsError(
            try store.create(
                date: TestCalendar.date(2026, 7, 12),
                durationMinutes: 60,
                hourlyRateCents: 2_300,
                now: TestCalendar.date(2026, 7, 11)
            )
        ) {
            XCTAssertEqual($0 as? EntryValidationError, .futureDate)
        }
        XCTAssertTrue(try store.allEntries().isEmpty)
    }

    func testDuplicateCreateThrowsAndLeavesExistingEntry() throws {
        let (_, store) = try makeStore()
        let original = try store.create(
            date: TestCalendar.date(2026, 7, 10),
            durationMinutes: 60,
            hourlyRateCents: 2_300,
            now: TestCalendar.date(2026, 7, 11)
        )
        let laterSameDay = try XCTUnwrap(
            TestCalendar.toronto.date(
                byAdding: .hour,
                value: 20,
                to: TestCalendar.date(2026, 7, 10)
            )
        )

        XCTAssertThrowsError(
            try store.create(
                date: laterSameDay,
                durationMinutes: 90,
                hourlyRateCents: 2_500,
                now: TestCalendar.date(2026, 7, 11)
            )
        ) {
            XCTAssertEqual($0 as? EntryValidationError, .duplicateDate(original.id))
        }
        XCTAssertEqual(try store.allEntries().map(\.id), [original.id])
    }

    func testUpdatePreservesHistoricalRate() throws {
        let (_, store) = try makeStore()
        let entry = try store.create(
            date: TestCalendar.date(2026, 7, 10),
            durationMinutes: 60,
            hourlyRateCents: 2_300,
            now: TestCalendar.date(2026, 7, 11)
        )
        let updateTime = try XCTUnwrap(
            TestCalendar.toronto.date(
                byAdding: .hour,
                value: 12,
                to: TestCalendar.date(2026, 7, 11)
            )
        )

        try store.update(
            entry,
            date: TestCalendar.date(2026, 7, 9),
            durationMinutes: 90,
            now: updateTime
        )

        XCTAssertEqual(entry.workDate, TestCalendar.date(2026, 7, 9))
        XCTAssertEqual(entry.hourlyRateCents, 2_300)
        XCTAssertEqual(entry.durationMinutes, 90)
        XCTAssertEqual(entry.updatedAt, updateTime)
    }

    func testRejectedUpdateDoesNotMutateEntry() throws {
        let (_, store) = try makeStore()
        _ = try store.create(
            date: TestCalendar.date(2026, 7, 9),
            durationMinutes: 45,
            hourlyRateCents: 2_300,
            now: TestCalendar.date(2026, 7, 11)
        )
        let entry = try store.create(
            date: TestCalendar.date(2026, 7, 10),
            durationMinutes: 60,
            hourlyRateCents: 2_500,
            now: TestCalendar.date(2026, 7, 11)
        )
        let originalUpdatedAt = entry.updatedAt

        XCTAssertThrowsError(
            try store.update(
                entry,
                date: TestCalendar.date(2026, 7, 9),
                durationMinutes: 120,
                now: TestCalendar.date(2026, 7, 11)
            )
        )
        XCTAssertEqual(entry.workDate, TestCalendar.date(2026, 7, 10))
        XCTAssertEqual(entry.durationMinutes, 60)
        XCTAssertEqual(entry.hourlyRateCents, 2_500)
        XCTAssertEqual(entry.updatedAt, originalUpdatedAt)
    }

    func testEntriesInPeriodAreFilteredAndSortedNewestFirst() throws {
        let (_, store) = try makeStore()
        let now = TestCalendar.date(2026, 7, 20)
        let outside = try store.create(
            date: TestCalendar.date(2026, 7, 2),
            durationMinutes: 30,
            hourlyRateCents: 2_300,
            now: now
        )
        let older = try store.create(
            date: TestCalendar.date(2026, 7, 4),
            durationMinutes: 60,
            hourlyRateCents: 2_300,
            now: now
        )
        let newer = try store.create(
            date: TestCalendar.date(2026, 7, 16),
            durationMinutes: 90,
            hourlyRateCents: 2_300,
            now: now
        )
        let period = PayPeriod(
            startDate: TestCalendar.date(2026, 7, 3),
            endDate: TestCalendar.date(2026, 7, 16),
            payday: TestCalendar.date(2026, 7, 17)
        )

        XCTAssertEqual(try store.entries(in: period).map(\.id), [newer.id, older.id])
        XCTAssertEqual(try store.allEntries().map(\.id), [newer.id, older.id, outside.id])
    }

    func testDeletePersistsRemoval() throws {
        let (container, store) = try makeStore()
        let entry = try store.create(
            date: TestCalendar.date(2026, 7, 10),
            durationMinutes: 60,
            hourlyRateCents: 2_300,
            now: TestCalendar.date(2026, 7, 11)
        )

        try store.delete(entry)

        let verificationContext = ModelContext(container)
        XCTAssertTrue(try verificationContext.fetch(FetchDescriptor<WorkEntry>()).isEmpty)
    }

    private func makeStore() throws -> (ModelContainer, EntryStore) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: WorkEntry.self,
            AppSettings.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        return (container, EntryStore(context: context, calendar: TestCalendar.toronto))
    }
}
