import SwiftData
import SwiftUI

struct EntriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkEntry.workDate, order: .reverse) private var entries: [WorkEntry]

    let environment: AppEnvironment
    let settings: EffectiveAppSettings
    let today: Date
    let onAdd: () -> Void
    let onEdit: (WorkEntry) -> Void

    @State private var pendingDeletion: WorkEntry?
    @State private var showsDeleteError = false

    init(
        environment: AppEnvironment,
        settings: EffectiveAppSettings,
        today: Date,
        onAdd: @escaping () -> Void,
        onEdit: @escaping (WorkEntry) -> Void
    ) {
        self.environment = environment
        self.settings = settings
        self.today = today
        self.onAdd = onAdd
        self.onEdit = onEdit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            if let snapshot {
                header(snapshot.period)
                entriesList(snapshot.entries)
            } else {
                Text(L10n.Entries.title)
                    .font(AppTypography.title)
                    .padding(.horizontal, AppSpacing.lg)

                ContentUnavailableView(
                    L10n.Overview.unavailableTitle,
                    systemImage: "exclamationmark.calendar",
                    description: Text(L10n.Overview.unavailableDescription)
                )
            }
        }
        .padding(.top, AppSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(AppColors.textLight)
        .background(AppColors.background.ignoresSafeArea())
        .confirmationDialog(
            L10n.Entries.deleteDialogTitle,
            isPresented: deletionDialogIsPresented,
            presenting: pendingDeletion
        ) { entry in
            Button(L10n.Entries.deleteDialogDelete, role: .destructive) { delete(entry) }
            Button(L10n.Entries.deleteDialogCancel, role: .cancel) {}
        } message: { _ in
            Text(L10n.Entries.deleteDialogMessage)
        }
        .alert(L10n.Entries.deleteErrorTitle, isPresented: $showsDeleteError) {
            Button(L10n.Entries.deleteErrorOk, role: .cancel) {}
        } message: {
            Text(L10n.Entries.deleteErrorMessage)
        }
    }

    private var snapshot: CurrentPeriodSnapshot? {
        try? CurrentPeriodSnapshot(
            entries: entries,
            anchorPayday: settings.anchorPayday,
            today: today,
            calendar: environment.calendar
        )
    }

    private var deletionDialogIsPresented: Binding<Bool> {
        Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        )
    }

    private func header(_ period: PayPeriod) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(L10n.Entries.title)
                .font(AppTypography.title)
                .fixedSize(horizontal: false, vertical: true)
            Text(L10n.Entries.currentPeriod)
                .font(.headline)
                .foregroundStyle(AppColors.gold)
            Text(AppFormatters.periodRange(period, calendar: environment.calendar))
                .font(.callout)
        }
        .padding(.horizontal, AppSpacing.lg)
        .accessibilityElement(children: .combine)
    }

    private func entriesList(_ currentEntries: [WorkEntry]) -> some View {
        List {
            if currentEntries.isEmpty {
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "clock")
                        .font(.title)
                        .foregroundStyle(AppColors.gold)
                        .accessibilityHidden(true)
                    Text(L10n.Entries.noWorkTime)
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.lg)
                .accessibilityElement(children: .combine)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(currentEntries, id: \.id) { entry in
                    WorkEntryCard(
                        entry: entry,
                        currencyCode: settings.currencyCode,
                        calendar: environment.calendar
                    ) {
                        onEdit(entry)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(L10n.Entries.deleteDialogDelete, systemImage: "trash", role: .destructive) {
                            pendingDeletion = entry
                        }
                    }
                    .listRowInsets(
                        EdgeInsets(
                            top: AppSpacing.xs,
                            leading: AppSpacing.lg,
                            bottom: AppSpacing.xs,
                            trailing: AppSpacing.lg
                        )
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }

            Button(action: onAdd) {
                Label(L10n.Entries.addTime, systemImage: "plus")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(AppColors.textDark)
                    .background(AppColors.surfaceCream)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.Entries.addTime)
            .listRowInsets(
                EdgeInsets(
                    top: AppSpacing.sm,
                    leading: AppSpacing.lg,
                    bottom: AppSpacing.lg,
                    trailing: AppSpacing.lg
                )
            )
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 1)
    }

    private func delete(_ entry: WorkEntry) {
        do {
            try EntryStore(context: modelContext, calendar: environment.calendar).delete(entry)
        } catch {
            showsDeleteError = true
        }
    }
}
