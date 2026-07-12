import SwiftUI

struct WorkEntryCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let entry: WorkEntry
    let currencyCode: String
    let calendar: Calendar
    let action: () -> Void

    init(
        entry: WorkEntry,
        currencyCode: String = "CAD",
        calendar: Calendar = .current,
        action: @escaping () -> Void
    ) {
        self.entry = entry
        self.currencyCode = currencyCode
        self.calendar = calendar
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        dateText
                        HStack(alignment: .bottom, spacing: AppSpacing.sm) {
                            metrics
                            disclosure
                        }
                    }
                } else {
                    HStack(spacing: AppSpacing.sm) {
                        dateText
                            .frame(maxWidth: .infinity, alignment: .leading)
                        metrics
                        disclosure
                    }
                }
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(AppColors.surfaceCream)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.card))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Opens work entry for editing")
    }

    private var dateText: some View {
        Text(AppFormatters.entryDate(entry.workDate, calendar: calendar))
            .font(.callout.weight(.medium))
            .foregroundStyle(AppColors.textDark)
            .multilineTextAlignment(.leading)
    }

    private var metrics: some View {
        VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: AppSpacing.xs) {
            Text(AppFormatters.duration(entry.durationMinutes))
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(AppColors.textDark)

            Text(AppFormatters.currency(cents: entry.earningsCents, code: currencyCode))
                .font(.callout.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(AppColors.gold)
        }
        .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil, alignment: .leading)
    }

    private var disclosure: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppColors.secondary)
            .accessibilityHidden(true)
    }

    private var accessibilityLabel: String {
        let date = AppFormatters.fullEntryDate(entry.workDate, calendar: calendar)
        let duration = AppFormatters.duration(entry.durationMinutes)
        let earnings = AppFormatters.currency(cents: entry.earningsCents, code: currencyCode)
        return "\(date), \(duration), \(earnings)"
    }
}
