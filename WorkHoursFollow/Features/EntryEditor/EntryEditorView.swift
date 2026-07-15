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
        (try? EarningsCalculator.earningsCents(
            durationMinutes: durationMinutes ?? 0,
            hourlyRateCents: hourlyRateCents
        )) ?? 0
    }

    func canSave(now: Date, calendar: Calendar) -> Bool {
        durationMinutes != nil
            && calendar.startOfDay(for: date) <= calendar.startOfDay(for: now)
    }

    func validationMessage(now: Date, calendar: Calendar) -> String? {
        guard calendar.startOfDay(for: date) <= calendar.startOfDay(for: now) else {
            return L10n.Editor.validationDate
        }
        guard durationMinutes != nil else {
            return L10n.Editor.validationDuration
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
            VStack(spacing: 0) {
                editorHeader

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
            }
            .toolbar(.hidden, for: .navigationBar)
            .tint(AppColors.accent)
        }
        .alert(
            presentedAlert?.title ?? "",
            isPresented: Binding(
                get: { presentedAlert != nil },
                set: { if !$0 { presentedAlert = nil } }
            ),
            presenting: presentedAlert
        ) { alert in
            switch alert {
            case .duplicate(let id):
                Button(L10n.Editor.duplicateEdit) {
                    editExistingEntry(id: id)
                }
                Button(L10n.Editor.duplicateReplace, role: .destructive) {
                    replaceExistingEntry(id: id)
                }
                Button(L10n.Editor.duplicateCancel, role: .cancel) {}
            case .persistence, .validation:
                Button(L10n.Editor.persistenceOk, role: .cancel) {}
            }
        } message: { alert in
            Text(alert.message)
        }
    }

    private var editorTitle: String {
        editingEntry == nil ? L10n.Editor.titleAdd : L10n.Editor.titleEdit
    }

    private var editorHeader: some View {
        VStack(spacing: dynamicTypeSize.isAccessibilitySize ? AppSpacing.xs : 0) {
            HStack(spacing: AppSpacing.xs) {
                headerButton(L10n.Editor.cancel, identifier: "entry-editor-cancel") {
                    dismiss()
                }

                Spacer(minLength: AppSpacing.xs)

                if !dynamicTypeSize.isAccessibilitySize {
                    editorHeaderTitle
                }

                Spacer(minLength: AppSpacing.xs)

                headerButton(L10n.Editor.save, identifier: "entry-editor-save", action: save)
                    .fontWeight(.semibold)
                    .disabled(
                        !state.canSave(
                            now: environment.now(),
                            calendar: environment.calendar
                        )
                    )
            }

            if dynamicTypeSize.isAccessibilitySize {
                editorHeaderTitle
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
        .foregroundStyle(AppColors.textLight)
        .background(AppColors.backgroundElevated)
    }

    private var editorHeaderTitle: some View {
        Text(editorTitle)
            .font(.headline)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .accessibilityIdentifier("entry-editor-title")
    }

    private func headerButton(
        _ title: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(title, action: action)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .frame(minWidth: 64, minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityIdentifier(identifier)
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionTitle(L10n.Editor.date)

            DatePicker(
                LocalizedStringKey(L10n.Editor.dateLabel),
                selection: $state.date,
                in: ...environment.now(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(AppColors.accent)
            .padding(AppSpacing.md)
            .foregroundStyle(AppColors.textLight)
            .background(panelBackground)
            .accessibilityHint(L10n.Editor.dateHint)
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionTitle(L10n.Editor.duration)

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
            title: L10n.Editor.durationHours,
            values: 0...24,
            selection: $state.hours,
            display: { String($0) }
        )
    }

    private var minutesPicker: some View {
        durationPicker(
            title: L10n.Editor.durationMinutes,
            values: 0...59,
            selection: $state.minutes,
            display: { String(format: "%02d", $0) }
        )
    }

    private var earningsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            earningsRow(
                label: L10n.Editor.earningsRate,
                value: L10n.Editor.earningsRateFormat(AppFormatters.currency(cents: state.hourlyRateCents, code: currencyCode))
            )
            Divider().overlay(AppColors.secondary.opacity(0.5))
            earningsRow(
                label: L10n.Editor.earningsEstimated,
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
        } catch EntryValidationError.nonPositiveDuration {
            presentedAlert = .validation(L10n.Editor.validationDuration)
        } catch EntryValidationError.nonPositiveHourlyRate {
            presentedAlert = .validation(
                L10n.Editor.validationRate
            )
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

    private func replaceExistingEntry(id: UUID) {
        guard let durationMinutes = state.durationMinutes else { return }
        let store = EntryStore(context: modelContext, calendar: environment.calendar)
        guard let entry = try? store.allEntries().first(where: { $0.id == id }) else {
            presentedAlert = .persistence
            return
        }
        
        do {
            try store.update(
                entry,
                date: state.date,
                durationMinutes: durationMinutes,
                now: environment.now()
            )
            dismiss()
        } catch {
            presentedAlert = .persistence
        }
    }
}

private enum EditorAlert: Identifiable {
    case duplicate(UUID)
    case persistence
    case validation(String)

    var id: String {
        switch self {
        case .duplicate(let id):
            "duplicate-\(id.uuidString)"
        case .persistence:
            "persistence"
        case .validation(let message):
            "validation-\(message)"
        }
    }

    var title: String {
        switch self {
        case .duplicate: return L10n.Editor.duplicateTitle
        case .persistence: return L10n.Editor.persistenceTitle
        case .validation: return L10n.Editor.validationTitle
        }
    }

    var message: String {
        switch self {
        case .duplicate: return L10n.Editor.duplicateMessage
        case .persistence: return L10n.Editor.persistenceMessage
        case .validation(let msg): return msg
        }
    }
}
