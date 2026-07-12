import Foundation
import SwiftData

@MainActor
struct EntryStore {
    let context: ModelContext
    let calendar: Calendar

    private var validator: EntryValidator {
        EntryValidator(calendar: calendar)
    }

    func allEntries() throws -> [WorkEntry] {
        let descriptor = FetchDescriptor<WorkEntry>(
            sortBy: [SortDescriptor(\.workDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func create(
        date: Date,
        durationMinutes: Int,
        hourlyRateCents: Int,
        now: Date
    ) throws -> WorkEntry {
        try validator.validate(
            date: date,
            now: now,
            existingEntries: try allEntries(),
            excluding: nil
        )

        let entry = WorkEntry(
            workDate: calendar.startOfDay(for: date),
            durationMinutes: durationMinutes,
            hourlyRateCents: hourlyRateCents,
            createdAt: now,
            updatedAt: now
        )
        context.insert(entry)
        try context.save()
        return entry
    }

    func update(
        _ entry: WorkEntry,
        date: Date,
        durationMinutes: Int,
        now: Date
    ) throws {
        try validator.validate(
            date: date,
            now: now,
            existingEntries: try allEntries(),
            excluding: entry.id
        )

        entry.workDate = calendar.startOfDay(for: date)
        entry.durationMinutes = durationMinutes
        entry.updatedAt = now
        try context.save()
    }

    func delete(_ entry: WorkEntry) throws {
        context.delete(entry)
        try context.save()
    }

    func entries(in period: PayPeriod) throws -> [WorkEntry] {
        try allEntries().filter { period.contains($0.workDate, calendar: calendar) }
    }
}
