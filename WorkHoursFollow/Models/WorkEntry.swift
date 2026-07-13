import Foundation
import SwiftData

@Model
final class WorkEntry {
    @Attribute(.unique) var id: UUID
    var workDate: Date
    var durationMinutes: Int
    var hourlyRateCents: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        workDate: Date,
        durationMinutes: Int,
        hourlyRateCents: Int,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.workDate = workDate
        self.durationMinutes = durationMinutes
        self.hourlyRateCents = hourlyRateCents
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }

    convenience init(
        workDate: Date,
        durationMinutes: Int,
        hourlyRateCents: Int,
        now: Date
    ) {
        self.init(
            workDate: workDate,
            durationMinutes: durationMinutes,
            hourlyRateCents: hourlyRateCents,
            createdAt: now,
            updatedAt: now
        )
    }

    var earningsCents: Int {
        (try? EarningsCalculator.earningsCents(
            durationMinutes: durationMinutes,
            hourlyRateCents: hourlyRateCents
        )) ?? 0
    }
}
