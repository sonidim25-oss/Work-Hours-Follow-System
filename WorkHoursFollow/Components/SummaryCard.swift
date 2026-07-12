import SwiftUI

struct SummaryCard: View {
    let totalTime: String
    let earnings: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            metric(label: "Total Hours", value: totalTime, valueColor: AppColors.textDark)

            Divider()
                .overlay(AppColors.textDark.opacity(0.12))

            metric(label: "Total Earned", value: earnings, valueColor: AppColors.gold)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surfaceCream)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
        .shadow(color: .black.opacity(0.10), radius: 8, y: 3)
        .accessibilityElement(children: .combine)
    }

    private func metric(label: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(label)
                .font(.body)
                .foregroundStyle(AppColors.textDark)

            Text(value)
                .font(AppTypography.metric)
                .monospacedDigit()
                .foregroundStyle(valueColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
