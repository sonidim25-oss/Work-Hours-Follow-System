import Foundation
import SwiftData

@Model
final class AppSettings {
    var defaultHourlyRateCents: Int
    var currencyCode: String
    var anchorPayday: Date
    var payPeriodLengthDays: Int

    init(
        defaultHourlyRateCents: Int,
        currencyCode: String,
        anchorPayday: Date,
        payPeriodLengthDays: Int
    ) {
        self.defaultHourlyRateCents = defaultHourlyRateCents
        self.currencyCode = currencyCode
        self.anchorPayday = anchorPayday
        self.payPeriodLengthDays = payPeriodLengthDays
    }
}
