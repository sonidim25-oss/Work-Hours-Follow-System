enum EarningsCalculator {
    enum RoundingStrategy {
        /// Half-up rounding for minute-to-hour conversions (cents).
        static func nearestCent(quotient: Int64, remainder: Int64, divisor: Int64 = 60) -> Int64 {
            let threshold = (divisor + 1) / 2 // 30 for 60
            return quotient + (remainder >= threshold ? 1 : 0)
        }
    }

    enum CalculationError: Error, Equatable {
        case negativeInput
        case overflow
    }

    /// Computes the total earnings in cents for a given duration and hourly rate.
    ///
    /// - Throws: `CalculationError.negativeInput` if either input is negative.
    ///           `CalculationError.overflow` if the result exceeds `Int.max`.
    static func earningsCents(durationMinutes: Int, hourlyRateCents: Int) throws -> Int {
        guard durationMinutes >= 0 && hourlyRateCents >= 0 else {
            throw CalculationError.negativeInput
        }
        let (numerator, overflow) = Int64(durationMinutes).multipliedReportingOverflow(by: Int64(hourlyRateCents))
        guard !overflow else {
            throw CalculationError.overflow
        }
        
        let quotient = numerator / 60
        let remainder = numerator % 60
        let total = RoundingStrategy.nearestCent(quotient: quotient, remainder: remainder)
        
        guard total <= Int64(Int.max) else {
            throw CalculationError.overflow
        }
        
        return Int(total)
    }
}
