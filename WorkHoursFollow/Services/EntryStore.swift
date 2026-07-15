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

    private func entries(for day: Date) throws -> [WorkEntry] {
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        let descriptor = FetchDescriptor<WorkEntry>(
            predicate: #Predicate { $0.workDate >= start && $0.workDate < end }
        )
        return try context.fetch(descriptor)
    }

    /// We use the main context for creation to ensure UI `@Query` properties update immediately.
    /// If `save()` fails, we delete the pending insertion to keep the context clean
    /// without calling `rollback()`, which would destroy other unrelated pending changes.
    func create(
        date: Date,
        durationMinutes: Int,
        hourlyRateCents: Int,
        now: Date
    ) throws -> WorkEntry {
        let normalizedDate = EntryValidator.normalizeStartOfDay(date: date, calendar: calendar)

        try validator.validate(
            durationMinutes: durationMinutes,
            hourlyRateCents: hourlyRateCents
        )
        try validator.validate(
            date: normalizedDate,
            now: now,
            existingEntries: try entries(for: normalizedDate),
            excluding: nil
        )

        let entry = WorkEntry(
            workDate: normalizedDate,
            durationMinutes: durationMinutes,
            hourlyRateCents: hourlyRateCents,
            now: now
        )
        
        context.insert(entry)
        
        do {
            try context.save()
            return entry
        } catch {
            context.delete(entry)
            throw error
        }
    }

    func update(
        _ entry: WorkEntry,
        date: Date,
        durationMinutes: Int,
        now: Date
    ) throws {
        let normalizedDate = EntryValidator.normalizeStartOfDay(date: date, calendar: calendar)

        try validator.validate(durationMinutes: durationMinutes)
        try validator.validate(
            date: normalizedDate,
            now: now,
            existingEntries: try entries(for: normalizedDate),
            excluding: entry.id
        )

        let originalDate = entry.workDate
        let originalDurationMinutes = entry.durationMinutes
        let originalUpdatedAt = entry.updatedAt
        entry.workDate = normalizedDate
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

    /// We use the main context for deletion to ensure UI `@Query` properties update immediately.
    ///
    /// Returns `true` if the entry was successfully found and deleted, or `false` if it
    /// was already absent from the persistent store.
    @discardableResult
    func delete(_ entry: WorkEntry) throws -> Bool {
        let entryID = entry.id
        let descriptor = FetchDescriptor<WorkEntry>(
            predicate: #Predicate { $0.id == entryID }
        )
        guard let persistedEntry = try context.fetch(descriptor).first else { return false }

        context.delete(persistedEntry)
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            throw error
        }
    }

    func entries(in period: PayPeriod) throws -> [WorkEntry] {
        let start = calendar.startOfDay(for: period.startDate)
        guard let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: period.endDate)) else { return [] }
        let descriptor = FetchDescriptor<WorkEntry>(
            predicate: #Predicate { $0.workDate >= start && $0.workDate < end },
            sortBy: [SortDescriptor(\.workDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
}

private enum EntryStoreError: Error {
    case createdEntryUnavailable
}

