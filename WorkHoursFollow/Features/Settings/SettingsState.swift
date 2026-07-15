import Foundation

struct SettingsState {
    var hourlyRateString: String
    var currencyCode: String
    var targetEarningsString: String

    init(settings: AppSettings) {
        let rateDouble = Double(settings.defaultHourlyRateCents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        self.hourlyRateString = formatter.string(from: NSNumber(value: rateDouble)) ?? ""
        self.currencyCode = settings.currencyCode
        
        if let target = settings.targetEarningsCents {
            let targetDouble = Double(target) / 100.0
            self.targetEarningsString = formatter.string(from: NSNumber(value: targetDouble)) ?? ""
        } else {
            self.targetEarningsString = ""
        }
    }

    var parsedHourlyRateCents: Int? {
        let sanitized = hourlyRateString.replacingOccurrences(of: ",", with: ".")
        guard let rate = Double(sanitized), rate > 0 else { return nil }
        return Int(round(rate * 100))
    }
    
    var parsedTargetEarningsCents: Int? {
        guard !targetEarningsString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        let sanitized = targetEarningsString.replacingOccurrences(of: ",", with: ".")
        guard let target = Double(sanitized), target > 0 else { return nil } // if invalid positive number, we can't save
        return Int(round(target * 100))
    }
    
    var isValid: Bool {
        parsedHourlyRateCents != nil && !currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
