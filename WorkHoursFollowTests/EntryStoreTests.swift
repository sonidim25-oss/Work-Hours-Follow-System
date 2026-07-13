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

    func testCreateRejectsNonPositiveDurationWithoutInserting() throws {
        for invalidDuration in [0, -1] {
            let (_, store) = try makeStore()

            XCTAssertThrowsError(
                try store.create(
                    date: TestCalendar.date(2026, 7, 10),
                    durationMinutes: invalidDuration,
                    hourlyRateCents: 2_300,
                    now: TestCalendar.date(2026, 7, 11)
                )
            ) {
                XCTAssertEqual($0 as? EntryValidationError, .nonPositiveDuration)
            }
            XCTAssertTrue(try store.allEntries().isEmpty)
        }
    }

    func testCreateRejectsNonPositiveHourlyRateWithoutInserting() throws {
        for invalidRate in [0, -1] {
            let (_, store) = try makeStore()

            XCTAssertThrowsError(
                try store.create(
                    date: TestCalendar.date(2026, 7, 10),
                    durationMinutes: 60,
                    hourlyRateCents: invalidRate,
                    now: TestCalendar.date(2026, 7, 11)
                )
            ) {
                XCTAssertEqual($0 as? EntryValidationError, .nonPositiveHourlyRate)
            }
            XCTAssertTrue(try store.allEntries().isEmpty)
        }
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

    func testUpdateRejectsNonPositiveDurationWithoutMutationOrUnsafeEarnings() throws {
        let (_, store) = try makeStore()
        let entry = try store.create(
            date: TestCalendar.date(2026, 7, 16),
            durationMinutes: 60,
            hourlyRateCents: 2_300,
            now: TestCalendar.date(2026, 7, 20)
        )
        let originalUpdatedAt = entry.updatedAt

        for invalidDuration in [0, -1] {
            XCTAssertThrowsError(
                try store.update(
                    entry,
                    date: TestCalendar.date(2026, 7, 17),
                    durationMinutes: invalidDuration,
                    now: TestCalendar.date(2026, 7, 20)
                )
            ) {
                XCTAssertEqual($0 as? EntryValidationError, .nonPositiveDuration)
            }
            XCTAssertEqual(entry.workDate, TestCalendar.date(2026, 7, 16))
            XCTAssertEqual(entry.durationMinutes, 60)
            XCTAssertEqual(entry.hourlyRateCents, 2_300)
            XCTAssertEqual(entry.updatedAt, originalUpdatedAt)
            XCTAssertEqual(entry.earningsCents, 2_300)
        }
    }

    func testMovingEntryAcrossPeriodsRecalculatesBothSummariesAndPreservesRate() throws {
        let (_, store) = try makeStore()
        let entry = try store.create(
            date: TestCalendar.date(2026, 7, 16),
            durationMinutes: 60,
            hourlyRateCents: 2_300,
            now: TestCalendar.date(2026, 7, 20)
        )
        let oldPeriod = PayPeriod(
            startDate: TestCalendar.date(2026, 7, 3),
            endDate: TestCalendar.date(2026, 7, 16),
            payday: TestCalendar.date(2026, 7, 17)
        )
        let newPeriod = PayPeriod(
            startDate: TestCalendar.date(2026, 7, 17),
            endDate: TestCalendar.date(2026, 7, 30),
            payday: TestCalendar.date(2026, 7, 31)
        )

        XCTAssertEqual(PeriodSummary(entries: try store.entries(in: oldPeriod)).totalMinutes, 60)
        XCTAssertEqual(PeriodSummary(entries: try store.entries(in: oldPeriod)).totalEarningsCents, 2_300)
        XCTAssertTrue(try store.entries(in: newPeriod).isEmpty)

        try store.update(
            entry,
            date: TestCalendar.date(2026, 7, 17),
            durationMinutes: 90,
            now: TestCalendar.date(2026, 7, 20)
        )

        let oldSummary = PeriodSummary(entries: try store.entries(in: oldPeriod))
        let newEntries = try store.entries(in: newPeriod)
        let newSummary = PeriodSummary(entries: newEntries)
        XCTAssertEqual(oldSummary.totalMinutes, 0)
        XCTAssertEqual(oldSummary.totalEarningsCents, 0)
        XCTAssertEqual(newEntries.map(\.id), [entry.id])
        XCTAssertEqual(newSummary.totalMinutes, 90)
        XCTAssertEqual(newSummary.totalEarningsCents, 3_450)
        XCTAssertEqual(entry.hourlyRateCents, 2_300)
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

    func testFailedUpdateRestoresEntryAndContext() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appending(path: "EntryStoreTests-\(UUID().uuidString).sqlite")
        let schema = Schema([WorkEntry.self, AppSettings.self])
        let writableConfiguration = ModelConfiguration(schema: schema, url: storeURL)
        let writableContainer = try ModelContainer(
            for: schema,
            configurations: [writableConfiguration]
        )
        let writableContext = ModelContext(writableContainer)
        let originalDate = TestCalendar.date(2026, 7, 10)
        let originalUpdatedAt = TestCalendar.date(2026, 7, 11)
        writableContext.insert(
            WorkEntry(
                workDate: originalDate,
                durationMinutes: 60,
                hourlyRateCents: 2_300,
                createdAt: originalUpdatedAt,
                updatedAt: originalUpdatedAt
            )
        )
        try writableContext.save()

        let readOnlyConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            allowsSave: false
        )
        let container = try ModelContainer(
            for: schema,
            configurations: [readOnlyConfiguration]
        )
        let context = ModelContext(container)
        let store = EntryStore(context: context, calendar: TestCalendar.toronto)
        let entry = try XCTUnwrap(store.allEntries().first)

        XCTAssertThrowsError(
            try store.update(
                entry,
                date: TestCalendar.date(2026, 7, 9),
                durationMinutes: 120,
                now: TestCalendar.date(2026, 7, 12)
            )
        )
        XCTAssertEqual(entry.workDate, originalDate)
        XCTAssertEqual(entry.durationMinutes, 60)
        XCTAssertEqual(entry.updatedAt, originalUpdatedAt)
        XCTAssertFalse(context.hasChanges)
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
        let periodStart = try store.create(
            date: TestCalendar.date(2026, 7, 3),
            durationMinutes: 45,
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

        XCTAssertEqual(
            try store.entries(in: period).map(\.id),
            [newer.id, older.id, periodStart.id]
        )
        XCTAssertEqual(
            try store.allEntries().map(\.id),
            [newer.id, older.id, periodStart.id, outside.id]
        )
    }

    func testDeletePersistsRemoval() throws {
        let (container, store) = try makeStore()
        let entry = try store.create(
            date: TestCalendar.date(2026, 7, 10),
            durationMinutes: 60,
            hourlyRateCents: 2_300,
            now: TestCalendar.date(2026, 7, 11)
        )
        let unselectedEntry = try store.create(
            date: TestCalendar.date(2026, 7, 9),
            durationMinutes: 30,
            hourlyRateCents: 2_300,
            now: TestCalendar.date(2026, 7, 11)
        )

        XCTAssertTrue(try store.delete(entry))

        XCTAssertEqual(try store.allEntries().map(\.id), [unselectedEntry.id])

        let verificationContext = ModelContext(container)
        XCTAssertEqual(
            try verificationContext.fetch(FetchDescriptor<WorkEntry>()).map(\.id),
            [unselectedEntry.id]
        )
    }

    func testIdempotentDeleteReturnsFalse() throws {
        let (_, store) = try makeStore()
        let missingEntry = WorkEntry(
            workDate: TestCalendar.date(2026, 7, 10),
            durationMinutes: 60,
            hourlyRateCents: 2_300,
            createdAt: TestCalendar.date(2026, 7, 11),
            updatedAt: TestCalendar.date(2026, 7, 11)
        )

        XCTAssertFalse(try store.delete(missingEntry))
        XCTAssertTrue(try store.allEntries().isEmpty)
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
