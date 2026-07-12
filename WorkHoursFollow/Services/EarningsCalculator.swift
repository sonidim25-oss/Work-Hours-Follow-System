enum EarningsCalculator {
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
        let total = quotient + (remainder >= 30 ? 1 : 0)
        
        guard total <= Int64(Int.max) else {
            return Int.max
        }
        
        return Int(total)
    }
}
