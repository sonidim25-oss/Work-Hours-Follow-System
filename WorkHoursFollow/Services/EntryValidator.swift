import Foundation

enum EntryValidationError: Error, Equatable {
    case futureDate
    case duplicateDate(UUID)
}

struct EntryValidator {
    let calendar: Calendar

    func validate(
        date: Date,
        now: Date,
        existingEntries: [WorkEntry],
        excluding id: UUID?
    ) throws {
        let day = calendar.startOfDay(for: date)
        guard day <= calendar.startOfDay(for: now) else {
            throw EntryValidationError.futureDate
        }

        if let duplicate = existingEntries.first(where: {
            $0.id != id && calendar.isDate($0.workDate, inSameDayAs: day)
        }) {
            throw EntryValidationError.duplicateDate(duplicate.id)
        }
    }
}
