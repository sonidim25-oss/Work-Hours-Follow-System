import Foundation

enum EntryValidationError: Error, Equatable {
    case nonPositiveDuration
    case nonPositiveHourlyRate
    case futureDate
    case duplicateDate(UUID)
}

struct EntryValidator {
    let calendar: Calendar

    func validate(durationMinutes: Int, hourlyRateCents: Int? = nil) throws {
        guard durationMinutes > 0 else {
            throw EntryValidationError.nonPositiveDuration
        }
        if let hourlyRateCents, hourlyRateCents <= 0 {
            throw EntryValidationError.nonPositiveHourlyRate
        }
    }

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
            $0.id != id && calendar.isDate($0.workDate, inSameDayAs: date)
        }) {
            throw EntryValidationError.duplicateDate(duplicate.id)
        }
    }
}
