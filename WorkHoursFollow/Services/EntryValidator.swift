import Foundation

enum EntryValidationError: Error, Equatable {
    case nonPositiveDuration
    case nonPositiveHourlyRate
    case futureDate
    case duplicateDate(UUID)
    case nonNormalizedDate
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

    static func normalizeStartOfDay(date: Date, calendar: Calendar) -> Date {
        calendar.startOfDay(for: date)
    }

    func validate(
        date: Date,
        now: Date,
        existingEntries: [WorkEntry],
        excluding id: UUID?
    ) throws {
        let normalizedDate = Self.normalizeStartOfDay(date: date, calendar: calendar)
        guard date == normalizedDate else {
            throw EntryValidationError.nonNormalizedDate
        }

        guard normalizedDate <= calendar.startOfDay(for: now) else {
            throw EntryValidationError.futureDate
        }

        if let duplicate = existingEntries.first(where: {
            $0.id != id && calendar.isDate($0.workDate, inSameDayAs: normalizedDate)
        }) {
            throw EntryValidationError.duplicateDate(duplicate.id)
        }
    }
}
