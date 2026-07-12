import SwiftData
import SwiftUI

struct OverviewView: View {
    @Query(sort: \WorkEntry.workDate, order: .reverse) private var entries: [WorkEntry]
    @Query private var settings: [AppSettings]

    let environment: AppEnvironment
    let today: Date
    let onAdd: () -> Void

    init(environment: AppEnvironment, today: Date, onAdd: @escaping () -> Void) {
        self.environment = environment
        self.today = today
        self.onAdd = onAdd
    }

    var body: some View {
        ScrollView {
            if let snapshot {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    Text("Work Hours Follow")
                        .font(AppTypography.title)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Current Pay Period")
                            .font(.headline)
                        Text(
                            AppFormatters.periodRange(
                                snapshot.period,
                                calendar: environment.calendar
                            )
                        )
                            .font(.callout)
                        Text("\(snapshot.elapsedDays) of 14 days")
                            .font(.caption)
                            .foregroundStyle(AppColors.secondary)
                        Text(
                            "Next payday: \(AppFormatters.shortDate(snapshot.period.payday, calendar: environment.calendar))"
                        )
                            .font(.callout)
                            .foregroundStyle(AppColors.gold)
                    }
                    .accessibilityElement(children: .combine)

                    SummaryCard(
                        totalTime: AppFormatters.duration(snapshot.summary.totalMinutes),
                        earnings: AppFormatters.currency(
                            cents: snapshot.summary.totalEarningsCents,
                            code: effectiveSettings.currencyCode
                        )
                    )

                    PrimaryButton(title: "Add Work Time", systemImage: "plus", action: onAdd)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.lg)
            } else {
                periodUnavailable
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(AppColors.textLight)
        .background(AppColors.background.ignoresSafeArea())
    }

    private var effectiveSettings: AppSettings {
        settings.first(where: {
            AppEnvironment.settingsAreValid($0, calendar: environment.calendar)
        }) ?? AppEnvironment.defaultSettings(calendar: environment.calendar)
    }

    private var snapshot: CurrentPeriodSnapshot? {
        try? CurrentPeriodSnapshot(
            entries: entries,
            anchorPayday: effectiveSettings.anchorPayday,
            today: today,
            calendar: environment.calendar
        )
    }

    private var periodUnavailable: some View {
        ContentUnavailableView(
            "Current Period Unavailable",
            systemImage: "exclamationmark.calendar",
            description: Text("The current pay period couldn’t be calculated.")
        )
        .foregroundStyle(AppColors.textLight)
        .padding(AppSpacing.lg)
    }
}
