enum EarningsCalculator {
    enum RoundingRule {
        /// Half-up rounding for minute-to-hour conversions (cents).
        static func apply(quotient: Int64, remainder: Int64, divisor: Int64 = 60) -> Int64 {
            let threshold = (divisor + 1) / 2 // 30 for 60
            return quotient + (remainder >= threshold ? 1 : 0)
        }
    }

    /// Computes the total earnings in cents for a given duration and hourly rate.
    ///
    /// - Returns: The calculated earnings. If negative inputs are provided, returns `0`.
    ///   If the calculation overflows the maximum representable integer, the result
    ///   is safely clamped to `Int.max` to prevent a crash, indicating an overflow.
    static func earningsCents(durationMinutes: Int, hourlyRateCents: Int) -> Int {
        guard durationMinutes >= 0 && hourlyRateCents >= 0 else {
            return 0
        }
        let (numerator, overflow) = Int64(durationMinutes).multipliedReportingOverflow(by: Int64(hourlyRateCents))
        guard !overflow else {
            return Int.max
        }
        
        let quotient = numerator / 60
        let remainder = numerator % 60
        let total = RoundingRule.apply(quotient: quotient, remainder: remainder)
        
        guard total <= Int64(Int.max) else {
            return Int.max
        }
        
        return Int(total)
    }
}
