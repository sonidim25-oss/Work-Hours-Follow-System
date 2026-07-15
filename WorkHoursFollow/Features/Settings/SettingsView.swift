import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [AppSettings]
    
    @State private var state: SettingsState?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text(L10n.Settings.title)
                    .font(AppTypography.title)
                    .foregroundStyle(AppColors.textLight)
                    .fixedSize(horizontal: false, vertical: true)

                if let state = state {
                    // Earnings Card
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text(L10n.Settings.sectionEarnings)
                            .font(.headline)
                            .foregroundStyle(AppColors.textDark)

                        HStack {
                            Text(L10n.Settings.hourlyRate)
                                .font(.body)
                                .foregroundStyle(AppColors.textDark)
                            Spacer()
                            TextField("0.00", text: Binding(
                                get: { state.hourlyRateString },
                                set: { self.state?.hourlyRateString = $0 }
                            ))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(AppColors.textDark)
                            .frame(width: 100)
                            .padding(AppSpacing.xs)
                            .background(Color.black.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
                        }

                        Divider()
                            .overlay(AppColors.textDark.opacity(0.12))

                        HStack {
                            Text(L10n.Settings.currency)
                                .font(.body)
                                .foregroundStyle(AppColors.textDark)
                            Spacer()
                            Picker(L10n.Settings.currency, selection: Binding(
                                get: { state.currencyCode },
                                set: { self.state?.currencyCode = $0 }
                            )) {
                                Text("CAD").tag("CAD")
                                Text("USD").tag("USD")
                                Text("EUR").tag("EUR")
                                Text("GBP").tag("GBP")
                            }
                            .tint(AppColors.accent)
                        }
                    }
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.surfaceCream)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
                    .shadow(color: .black.opacity(0.10), radius: 8, y: 3)

                    // Goals Card
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text(L10n.Settings.sectionGoals)
                            .font(.headline)
                            .foregroundStyle(AppColors.textDark)

                        HStack {
                            Text(L10n.Settings.targetEarnings)
                                .font(.body)
                                .foregroundStyle(AppColors.textDark)
                            Spacer()
                            TextField("Optional", text: Binding(
                                get: { state.targetEarningsString },
                                set: { self.state?.targetEarningsString = $0 }
                            ))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(AppColors.textDark)
                            .frame(width: 100)
                            .padding(AppSpacing.xs)
                            .background(Color.black.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
                        }
                    }
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.surfaceCream)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
                    .shadow(color: .black.opacity(0.10), radius: 8, y: 3)
                    
                    PrimaryButton(title: L10n.Settings.save, systemImage: "checkmark") {
                        saveSettings()
                    }
                    .disabled(!state.isValid)
                    .padding(.top, AppSpacing.md)
                    
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
        .onAppear {
            if let currentSettings = settingsQuery.first {
                state = SettingsState(settings: currentSettings)
            }
        }
    }
    
    private func saveSettings() {
        guard let state = state, state.isValid,
              let rate = state.parsedHourlyRateCents else { return }
        
        let target = state.parsedTargetEarningsCents
        
        if let currentSettings = settingsQuery.first {
            currentSettings.defaultHourlyRateCents = rate
            currentSettings.currencyCode = state.currencyCode
            currentSettings.targetEarningsCents = target
            
            try? modelContext.save()
        }
    }
}
