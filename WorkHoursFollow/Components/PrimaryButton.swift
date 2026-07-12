import SwiftUI

struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(
        title: String,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .accessibilityHidden(true)
                }

                Text(title)
                    .font(.body.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(PrimaryButtonStyle())
        .accessibilityLabel(title)
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(AppColors.textLight)
            .background(AppColors.accent)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
            .opacity(isEnabled ? (configuration.isPressed ? 0.82 : 1) : 0.45)
    }
}
