import SwiftData
import XCTest
@testable import WorkHoursFollow

@MainActor
final class EntryValidatorTests: XCTestCase {
    func testRejectsFutureDate() throws {
        let context = try makeContext()
        let validator = EntryValidator(calendar: TestCalendar.toronto)

        XCTAssertThrowsError(
            try validator.validate(
                date: TestCalendar.date(2026, 7, 12),
                now: TestCalendar.date(2026, 7, 11),
                existingEntries: try context.fetch(FetchDescriptor<WorkEntry>()),
                excluding: nil
            )
        ) {
            XCTAssertEqual($0 as? EntryValidationError, .futureDate)
        }
    }

    func testRejectsTwoTimestampsOnTheSameCalendarDate() throws {
        let context = try makeContext()
        let calendar = TestCalendar.toronto
        let morning = try XCTUnwrap(
            calendar.date(byAdding: .hour, value: 8, to: TestCalendar.date(2026, 7, 10))
        )
        let evening = try XCTUnwrap(
            calendar.date(byAdding: .hour, value: 19, to: TestCalendar.date(2026, 7, 10))
        )
        let existing = WorkEntry(
            workDate: morning,
            durationMinutes: 60,
            hourlyRateCents: 2_300,
            createdAt: morning,
            updatedAt: morning
        )
        context.insert(existing)
        try context.save()

        let validator = EntryValidator(calendar: calendar)

        XCTAssertThrowsError(
            try validator.validate(
                date: evening,
                now: TestCalendar.date(2026, 7, 11),
                existingEntries: try context.fetch(FetchDescriptor<WorkEntry>()),
                excluding: nil
            )
        ) {
            XCTAssertEqual($0 as? EntryValidationError, .duplicateDate(existing.id))
        }
    }

    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: WorkEntry.self,
            AppSettings.self,
            configurations: configuration
        )
        return ModelContext(container)
    }
}
