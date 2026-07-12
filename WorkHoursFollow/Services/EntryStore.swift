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

    /// We use a dedicated child context for creation to prevent polluting the main
    /// context with an unsaved insertion. If `save()` fails, we can cleanly discard
    /// the child context without needing to call `rollback()` on the main context,
    /// which would inadvertently destroy any other unrelated pending changes.
    func create(
        date: Date,
        durationMinutes: Int,
        hourlyRateCents: Int,
        now: Date
    ) throws -> WorkEntry {
        try validator.validate(
            durationMinutes: durationMinutes,
            hourlyRateCents: hourlyRateCents
        )
        try validator.validate(
            date: date,
            now: now,
            existingEntries: try entries(for: date),
            excluding: nil
        )

        let entry = WorkEntry(
            workDate: calendar.startOfDay(for: date),
            durationMinutes: durationMinutes,
            hourlyRateCents: hourlyRateCents,
            now: now
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
        try validator.validate(durationMinutes: durationMinutes)
        try validator.validate(
            date: date,
            now: now,
            existingEntries: try entries(for: date),
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

    /// We use a dedicated child context for deletion because calling `context.delete()`
    /// irrevocably mutates the in-memory object state. If the subsequent `save()` fails,
    /// we cannot safely "undelete" the object or roll back the context without leaving
    /// the main context and its loaded models in an inconsistent, corrupted state.
    ///
    /// If the entry is no longer present in the persistent store, this method returns
    /// silently, as the desired end state (the entry being deleted) is already met.
    func delete(_ entry: WorkEntry) throws {
        let entryID = entry.id
        let deletionContext = ModelContext(context.container)
        deletionContext.autosaveEnabled = false
        let descriptor = FetchDescriptor<WorkEntry>(
            predicate: #Predicate { $0.id == entryID }
        )
        guard let persistedEntry = try deletionContext.fetch(descriptor).first else { return }

        deletionContext.delete(persistedEntry)
        try deletionContext.save()
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

