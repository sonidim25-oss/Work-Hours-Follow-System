import SwiftData
import SwiftUI

struct EntriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkEntry.workDate, order: .reverse) private var entries: [WorkEntry]
    @Query private var settings: [AppSettings]

    let environment: AppEnvironment
    let today: Date
    let onAdd: () -> Void
    let onEdit: (WorkEntry) -> Void

    @State private var pendingDeletion: WorkEntry?
    @State private var showsDeleteError = false

    init(
        environment: AppEnvironment,
        today: Date,
        onAdd: @escaping () -> Void,
        onEdit: @escaping (WorkEntry) -> Void
    ) {
        self.environment = environment
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
                Text("Entries")
                    .font(AppTypography.title)
                    .padding(.horizontal, AppSpacing.lg)

                ContentUnavailableView(
                    "Current Period Unavailable",
                    systemImage: "exclamationmark.calendar",
                    description: Text("The current pay period couldn’t be calculated.")
                )
            }
        }
        .padding(.top, AppSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(AppColors.textLight)
        .background(AppColors.background.ignoresSafeArea())
        .confirmationDialog(
            "Delete Work Entry?",
            isPresented: deletionDialogIsPresented,
            presenting: pendingDeletion
        ) { entry in
            Button("Delete", role: .destructive) { delete(entry) }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("This work entry will be permanently removed.")
        }
        .alert("Couldn’t Delete Work Entry", isPresented: $showsDeleteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The entry is still here. Please try deleting it again.")
        }
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

    private var deletionDialogIsPresented: Binding<Bool> {
        Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        )
    }

    private func header(_ period: PayPeriod) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Entries")
                .font(AppTypography.title)
                .fixedSize(horizontal: false, vertical: true)
            Text("Current Pay Period")
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
                    Text("No work time recorded for this period.")
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
                        currencyCode: effectiveSettings.currencyCode,
                        calendar: environment.calendar
                    ) {
                        onEdit(entry)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Delete", systemImage: "trash", role: .destructive) {
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
                Label("Add Time for a Day", systemImage: "plus")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(AppColors.textDark)
                    .background(AppColors.surfaceCream)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add Time for a Day")
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
