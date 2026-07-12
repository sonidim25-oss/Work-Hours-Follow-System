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
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.workDate = workDate
        self.durationMinutes = durationMinutes
        self.hourlyRateCents = hourlyRateCents
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var earningsCents: Int {
        EarningsCalculator.earningsCents(
            durationMinutes: durationMinutes,
            hourlyRateCents: hourlyRateCents
        )
    }
}
