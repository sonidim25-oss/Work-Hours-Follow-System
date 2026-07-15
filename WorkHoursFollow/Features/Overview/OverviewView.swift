import SwiftData
import SwiftUI

struct OverviewView: View {
    @Query(sort: \WorkEntry.workDate, order: .reverse) private var entries: [WorkEntry]

    let environment: AppEnvironment
    let settings: EffectiveAppSettings
    let today: Date
    let onAdd: () -> Void

    init(
        environment: AppEnvironment,
        settings: EffectiveAppSettings,
        today: Date,
        onAdd: @escaping () -> Void
    ) {
        self.environment = environment
        self.settings = settings
        self.today = today
        self.onAdd = onAdd
    }

    @State private var showConfetti = false

    var body: some View {
        ZStack {
            ScrollView {
                if let snapshot {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        Text(L10n.appName)
                            .font(AppTypography.title)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(L10n.Overview.currentPeriod)
                                .font(.headline)
                            Text(
                                AppFormatters.periodRange(
                                    snapshot.period,
                                    calendar: environment.calendar
                                )
                            )
                                .font(.callout)
                            Text(L10n.Overview.elapsedDays(snapshot.elapsedDays))
                                .font(.caption)
                                .foregroundStyle(AppColors.secondary)
                            Text(L10n.Overview.nextPayday(AppFormatters.shortDate(snapshot.period.payday, calendar: environment.calendar)))
                                .font(.callout)
                                .foregroundStyle(AppColors.gold)
                        }
                        .accessibilityElement(children: .combine)

                        SummaryCard(
                            totalTime: AppFormatters.duration(snapshot.summary.totalMinutes),
                            earnings: AppFormatters.currency(
                                cents: snapshot.summary.totalEarningsCents,
                                code: settings.currencyCode
                            )
                        )
                        
                        if let targetCents = settings.targetEarningsCents, targetCents > 0 {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text("Earnings Goal")
                                    .font(.headline)
                                
                                let targetFormatted = AppFormatters.currency(cents: targetCents, code: settings.currencyCode)
                                let currentFormatted = AppFormatters.currency(cents: snapshot.summary.totalEarningsCents, code: settings.currencyCode)
                                
                                Text("\(currentFormatted) / \(targetFormatted)")
                                    .font(.callout)
                                
                                ProgressView(value: min(Double(snapshot.summary.totalEarningsCents) / Double(targetCents), 1.0))
                                    .tint(AppColors.accent)
                            }
                            .padding(.top, AppSpacing.sm)
                        }

                        PrimaryButton(title: L10n.Overview.addWorkTime, systemImage: "plus", action: onAdd)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.lg)
                    .onChange(of: snapshot.summary.totalEarningsCents, initial: true) { _, newValue in
                        if let target = settings.targetEarningsCents, target > 0, newValue >= target {
                            showConfetti = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                showConfetti = false
                            }
                        } else {
                            showConfetti = false
                        }
                    }
                } else {
                    periodUnavailable
                }
            }
            
            ConfettiView(isEmitting: $showConfetti)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(AppColors.textLight)
        .background(AppColors.background.ignoresSafeArea())
    }

    private var snapshot: CurrentPeriodSnapshot? {
        try? CurrentPeriodSnapshot(
            entries: entries,
            anchorPayday: settings.anchorPayday,
            today: today,
            calendar: environment.calendar
        )
    }

    private var periodUnavailable: some View {
        ContentUnavailableView(
            L10n.Overview.unavailableTitle,
            systemImage: "exclamationmark.calendar",
            description: Text(L10n.Overview.unavailableDescription)
        )
        .foregroundStyle(AppColors.textLight)
        .padding(AppSpacing.lg)
    }
}
