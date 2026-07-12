import SwiftUI

struct WorkEntryCard: View {
    let entry: WorkEntry
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Text(AppFormatters.entryDate(entry.workDate))
                    .font(.callout.weight(.medium))
                    .foregroundStyle(AppColors.textDark)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                    Text(AppFormatters.duration(entry.durationMinutes))
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(AppColors.textDark)

                    Text(AppFormatters.currency(cents: entry.earningsCents))
                        .font(.callout.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(AppColors.textDark)
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.secondary)
                    .accessibilityHidden(true)
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

    private var accessibilityLabel: String {
        let date = AppFormatters.fullEntryDate(entry.workDate)
        let duration = AppFormatters.duration(entry.durationMinutes)
        let earnings = AppFormatters.currency(cents: entry.earningsCents)
        return "\(date), \(duration), \(earnings)"
    }
}
