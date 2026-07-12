import Foundation
import SwiftData
import SwiftUI

struct EntryEditorState {
    var date: Date
    var hours: Int
    var minutes: Int
    let hourlyRateCents: Int

    init(
        date: Date,
        hours: Int = 0,
        minutes: Int = 0,
        hourlyRateCents: Int
    ) {
        self.date = date
        self.hours = hours
        self.minutes = minutes
        self.hourlyRateCents = hourlyRateCents
    }

    init(entry: WorkEntry) {
        date = entry.workDate
        hours = entry.durationMinutes / 60
        minutes = entry.durationMinutes % 60
        hourlyRateCents = entry.hourlyRateCents
    }

    var durationMinutes: Int? {
        try? DurationService.totalMinutes(hours: hours, minutes: minutes)
    }

    var earningsCents: Int {
        EarningsCalculator.earningsCents(
            durationMinutes: durationMinutes ?? 0,
            hourlyRateCents: hourlyRateCents
        )
    }

    func canSave(now: Date, calendar: Calendar) -> Bool {
        durationMinutes != nil
            && calendar.startOfDay(for: date) <= calendar.startOfDay(for: now)
    }

    func validationMessage(now: Date, calendar: Calendar) -> String? {
        guard calendar.startOfDay(for: date) <= calendar.startOfDay(for: now) else {
            return "Choose today or an earlier date."
        }
        guard durationMinutes != nil else {
            return "Enter a work duration greater than zero."
        }
        return nil
    }
}

enum EditorRoute: Identifiable {
    case create
    case edit(WorkEntry)

    enum ID: Hashable {
        case create
        case edit(UUID)
    }

    var id: ID {
        switch self {
        case .create:
            .create
        case .edit(let entry):
            .edit(entry.id)
        }
    }

    fileprivate var entry: WorkEntry? {
        switch self {
        case .create:
            nil
        case .edit(let entry):
            entry
        }
    }
}

struct EntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.modelContext) private var modelContext

    let environment: AppEnvironment
    let currencyCode: String

    @State private var state: EntryEditorState
    @State private var editingEntry: WorkEntry?
    @State private var presentedAlert: EditorAlert?

    init(route: EditorRoute, environment: AppEnvironment, settings: EffectiveAppSettings) {
        self.environment = environment
        currencyCode = settings.currencyCode
        let entry = route.entry
        _editingEntry = State(initialValue: entry)
        _state = State(
            initialValue: entry.map(EntryEditorState.init(entry:))
                ?? EntryEditorState(
                    date: environment.now(),
                    hourlyRateCents: settings.defaultHourlyRateCents
                )
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    dateSection
                    durationSection
                    earningsSection

                    if let validationMessage = state.validationMessage(
                        now: environment.now(),
                        calendar: environment.calendar
                    ) {
                        Label(validationMessage, systemImage: "exclamationmark.circle")
                            .font(.callout)
                            .foregroundStyle(AppColors.textLight)
                            .accessibilityIdentifier("entry-editor-validation")
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.lg)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle(editingEntry == nil ? "Add Work Time" : "Edit Work Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.backgroundElevated, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColors.textLight)
                        .frame(minWidth: 44, minHeight: 44)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.textLight)
                        .frame(minWidth: 44, minHeight: 44)
                        .disabled(
                            !state.canSave(
                                now: environment.now(),
                                calendar: environment.calendar
                            )
                        )
                        .accessibilityIdentifier("entry-editor-save")
                }
            }
            .tint(AppColors.accent)
        }
        .alert(item: $presentedAlert) { alert in
            switch alert {
            case .duplicate(let id):
                Alert(
                    title: Text("Entry Already Exists"),
                    message: Text("There is already work time recorded for this date."),
                    primaryButton: .default(Text("Edit Existing Entry")) {
                        editExistingEntry(id: id)
                    },
                    secondaryButton: .cancel()
                )
            case .persistence:
                Alert(
                    title: Text("Couldn’t Save Work Time"),
                    message: Text("Your changes are still here. Please try saving again."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionTitle("Date")

            DatePicker(
                "Work date",
                selection: $state.date,
                in: ...environment.now(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(AppColors.accent)
            .padding(AppSpacing.md)
            .foregroundStyle(AppColors.textLight)
            .background(panelBackground)
            .accessibilityHint("Choose today or an earlier work date")
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionTitle("Total Time Worked")

            durationPickers
            .padding(.horizontal, AppSpacing.sm)
            .background(panelBackground)
        }
    }

    @ViewBuilder
    private var durationPickers: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: AppSpacing.md) {
                hoursPicker
                minutesPicker
            }
        } else {
            HStack(spacing: AppSpacing.md) {
                hoursPicker
                minutesPicker
            }
        }
    }

    private var hoursPicker: some View {
        durationPicker(
            title: "Hours",
            values: 0...24,
            selection: $state.hours,
            display: { String($0) }
        )
    }

    private var minutesPicker: some View {
        durationPicker(
            title: "Minutes",
            values: 0...59,
            selection: $state.minutes,
            display: { String(format: "%02d", $0) }
        )
    }

    private var earningsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            earningsRow(
                label: "Rate",
                value: "\(AppFormatters.currency(cents: state.hourlyRateCents, code: currencyCode)) / hour"
            )
            Divider().overlay(AppColors.secondary.opacity(0.5))
            earningsRow(
                label: "Estimated earned",
                value: AppFormatters.currency(cents: state.earningsCents, code: currencyCode)
            )
        }
        .padding(AppSpacing.md)
        .background(panelBackground)
        .accessibilityElement(children: .combine)
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: AppRadius.card)
            .fill(AppColors.backgroundElevated)
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .stroke(AppColors.secondary.opacity(0.35), lineWidth: 1)
            }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .foregroundStyle(AppColors.textLight)
    }

    private func durationPicker(
        title: String,
        values: ClosedRange<Int>,
        selection: Binding<Int>,
        display: @escaping (Int) -> String
    ) -> some View {
        VStack(spacing: 0) {
            Picker(title, selection: selection) {
                ForEach(values, id: \.self) { value in
                    Text(display(value))
                        .font(.title2.monospacedDigit())
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
            .clipped()
            .accessibilityValue(display(selection.wrappedValue))

            Text(title.lowercased())
                .font(.caption)
                .foregroundStyle(AppColors.secondary)
                .padding(.bottom, AppSpacing.sm)
        }
        .foregroundStyle(AppColors.textLight)
    }

    private func earningsRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
            Text(label)
                .foregroundStyle(AppColors.textLight)
            Spacer(minLength: AppSpacing.sm)
            Text(value)
                .font(.body.weight(.semibold).monospacedDigit())
                .foregroundStyle(AppColors.gold)
                .multilineTextAlignment(.trailing)
        }
    }

    private func save() {
        guard let durationMinutes = state.durationMinutes else { return }
        let store = EntryStore(context: modelContext, calendar: environment.calendar)

        do {
            if let editingEntry {
                try store.update(
                    editingEntry,
                    date: state.date,
                    durationMinutes: durationMinutes,
                    now: environment.now()
                )
            } else {
                _ = try store.create(
                    date: state.date,
                    durationMinutes: durationMinutes,
                    hourlyRateCents: state.hourlyRateCents,
                    now: environment.now()
                )
            }
            dismiss()
        } catch EntryValidationError.duplicateDate(let id) {
            presentedAlert = .duplicate(id)
        } catch {
            presentedAlert = .persistence
        }
    }

    private func editExistingEntry(id: UUID) {
        let store = EntryStore(context: modelContext, calendar: environment.calendar)
        guard let entry = try? store.allEntries().first(where: { $0.id == id }) else {
            presentedAlert = .persistence
            return
        }
        editingEntry = entry
        state = EntryEditorState(entry: entry)
    }
}

private enum EditorAlert: Identifiable {
    case duplicate(UUID)
    case persistence

    var id: String {
        switch self {
        case .duplicate(let id):
            "duplicate-\(id.uuidString)"
        case .persistence:
            "persistence"
        }
    }
}
