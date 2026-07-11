enum EarningsCalculator {
    static func earningsCents(durationMinutes: Int, hourlyRateCents: Int) -> Int {
        precondition(durationMinutes >= 0 && hourlyRateCents >= 0)
        let numerator = durationMinutes * hourlyRateCents
        let quotient = numerator / 60
        let remainder = numerator % 60
        return quotient + (remainder >= 30 ? 1 : 0)
    }
}
