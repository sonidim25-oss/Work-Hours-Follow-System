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
        let creationContext = ModelContext(context.container)
        creationContext.autosaveEnabled = false
        creationContext.insert(entry)
        try creationContext.save()

        guard let persistedEntry = try allEntries().first(where: { $0.id == entry.id }) else {
            throw EntryStoreError.createdEntryUnavailable
        }
        return persistedEntry
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

        let originalDate = entry.workDate
        let originalDurationMinutes = entry.durationMinutes
        let originalUpdatedAt = entry.updatedAt
        entry.workDate = calendar.startOfDay(for: date)
        entry.durationMinutes = durationMinutes
        entry.updatedAt = now
        do {
            try context.save()
        } catch {
            entry.workDate = originalDate
            entry.durationMinutes = originalDurationMinutes
            entry.updatedAt = originalUpdatedAt
            context.rollback()
            throw error
        }
    }

    func delete(_ entry: WorkEntry) throws {
        context.delete(entry)
        try context.save()
    }

    func entries(in period: PayPeriod) throws -> [WorkEntry] {
        try allEntries().filter { period.contains($0.workDate, calendar: calendar) }
    }
}

private enum EntryStoreError: Error {
    case createdEntryUnavailable
}
