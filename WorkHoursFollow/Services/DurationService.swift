import Foundation

enum DurationValidationError: Error, Equatable {
    case negativeHours
    case invalidMinutes
    case zeroDuration
}

enum DurationService {
    static func totalMinutes(hours: Int, minutes: Int) throws -> Int {
        guard hours >= 0 else { throw DurationValidationError.negativeHours }
        guard (0...59).contains(minutes) else { throw DurationValidationError.invalidMinutes }
        let total = hours * 60 + minutes
        guard total > 0 else { throw DurationValidationError.zeroDuration }
        return total
    }
}
