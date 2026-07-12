import SwiftUI

struct HistoryPlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("History")
                .font(AppTypography.title)

            ContentUnavailableView(
                "History Comes Next",
                systemImage: "clock.arrow.circlepath",
                description: Text("Completed pay periods will be added in a later milestone.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(AppColors.textLight)
        .background(AppColors.background.ignoresSafeArea())
    }
}
