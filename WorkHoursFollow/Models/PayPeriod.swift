import Foundation

struct PayPeriod: Equatable, Sendable {
    let startDate: Date
    let endDate: Date
    let payday: Date

    func contains(_ date: Date, calendar: Calendar) -> Bool {
        let day = calendar.startOfDay(for: date)
        return day >= startDate && day <= endDate
    }
}

struct PeriodSummary {
    let totalMinutes: Int
    let totalEarningsCents: Int?

    init(entries: [WorkEntry]) {
        totalMinutes = entries.reduce(0) { $0 + $1.durationMinutes }
        
        var totalCents: Int? = 0
        for entry in entries {
            if let current = totalCents, let cents = entry.earningsCents {
                let (sum, overflow) = current.addingReportingOverflow(cents)
                totalCents = overflow ? nil : sum
            } else {
                totalCents = nil
            }
        }
        totalEarningsCents = totalCents
    }
}

struct CurrentPeriodSnapshot {
    let period: PayPeriod
    let entries: [WorkEntry]
    let summary: PeriodSummary
    let elapsedDays: Int

    init(
        entries: [WorkEntry],
        anchorPayday: Date,
        today: Date,
        calendar: Calendar
    ) throws {
        let resolvedPeriod = try PayPeriodCalculator(calendar: calendar).period(
            containing: today,
            anchorPayday: anchorPayday
        )
        let filteredEntries = entries
            .filter { resolvedPeriod.contains($0.workDate, calendar: calendar) }
            .sorted { $0.workDate > $1.workDate }
        let resolvedSummary = PeriodSummary(entries: filteredEntries)

        let normalizedToday = calendar.startOfDay(for: today)
        let daysFromStart = calendar.dateComponents(
            [.day],
            from: resolvedPeriod.startDate,
            to: normalizedToday
        ).day ?? 0
        let resolvedElapsedDays = min(max(daysFromStart + 1, 1), 14)

        period = resolvedPeriod
        self.entries = filteredEntries
        summary = resolvedSummary
        elapsedDays = resolvedElapsedDays
    }
}
