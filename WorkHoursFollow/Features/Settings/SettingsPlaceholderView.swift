import SwiftUI

struct SettingsPlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Settings")
                .font(AppTypography.title)

            ContentUnavailableView(
                "Settings Come Next",
                systemImage: "gearshape.fill",
                description: Text("Editable preferences will be added in a later milestone.")
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
