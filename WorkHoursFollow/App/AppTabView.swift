import SwiftData
import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case overview, entries, history, settings

    var title: String {
        switch self {
        case .overview: L10n.Tab.overview
        case .entries: L10n.Tab.entries
        case .history: L10n.Tab.history
        case .settings: L10n.Tab.settings
        }
    }
}

struct AppTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var settings: [AppSettings]

    let environment: AppEnvironment

    @State private var editorRoute: EditorRoute?
    @State private var settingsNotice: SettingsNotice?
    @State private var today: Date
#if DEBUG
    @State private var uiTestResetComplete = false
#endif

    init(environment: AppEnvironment) {
        self.environment = environment
        _today = State(initialValue: environment.now())
    }

    var body: some View {
        TabView {
            OverviewView(
                environment: environment,
                settings: effectiveSettings,
                today: today
            ) {
                editorRoute = .create
            }
            .tabItem { Label(L10n.Tab.overview, systemImage: "house.fill") }

            EntriesView(
                environment: environment,
                settings: effectiveSettings,
                today: today,
                onAdd: { editorRoute = .create },
                onEdit: { editorRoute = .edit($0) }
            )
            .tabItem { Label(L10n.Tab.entries, systemImage: "list.bullet.rectangle") }

            HistoryPlaceholderView()
                .tabItem { Label(L10n.Tab.history, systemImage: "clock.arrow.circlepath") }

            SettingsPlaceholderView()
                .tabItem { Label(L10n.Tab.settings, systemImage: "gearshape.fill") }
        }
        .tint(AppColors.accent)
        .toolbarBackground(AppColors.backgroundElevated, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .task { prepareInitialData() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                today = environment.now()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            today = environment.now()
        }
        .sheet(item: $editorRoute) { route in
            EntryEditorView(
                route: route,
                environment: environment,
                settings: effectiveSettings
            )
        }
        .alert(item: $settingsNotice) { notice in
            Alert(
                title: Text(notice.title),
                message: Text(notice.message),
                dismissButton: .default(Text(L10n.Settings.ok))
            )
        }
        .overlay(alignment: .topLeading) {
#if DEBUG
            if uiTestResetComplete {
                Color.clear
                    .frame(width: 1, height: 1)
                    .accessibilityElement()
                    .accessibilityLabel("UI test reset complete")
                    .accessibilityIdentifier("ui-test-reset-complete")
                    .allowsHitTesting(false)
            }
#endif
        }
    }

    private var settingsResolution: AppSettingsResolution {
        AppSettingsResolution.resolve(settings, calendar: environment.calendar, now: environment.now())
    }

    private var effectiveSettings: EffectiveAppSettings {
        settingsResolution.effective
    }

    private func prepareInitialData() {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing-reset-data") {
            resetUITestData()
            return
        }
#endif
        restoreSettingsIfNeeded()
    }

#if DEBUG
    private func resetUITestData() {
        do {
            try modelContext.fetch(FetchDescriptor<WorkEntry>()).forEach(modelContext.delete)
            try modelContext.fetch(FetchDescriptor<AppSettings>()).forEach(modelContext.delete)
            modelContext.insert(AppEnvironment.defaultSettings(calendar: environment.calendar, now: environment.now()))
            try modelContext.save()
            uiTestResetComplete = true
        } catch {
            modelContext.rollback()
            settingsNotice = .restoreFailed
        }
    }
#endif

    private func restoreSettingsIfNeeded() {
        guard settingsResolution.needsRepair else { return }

        settings.forEach { modelContext.delete($0) }
        modelContext.insert(AppEnvironment.defaultSettings(calendar: environment.calendar, now: environment.now()))

        do {
            try modelContext.save()
            settingsNotice = .restored
        } catch {
            modelContext.rollback()
            settingsNotice = .restoreFailed
        }
    }
}

private enum SettingsNotice: String, Identifiable {
    case restored
    case restoreFailed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .restored: L10n.Settings.restoredTitle
        case .restoreFailed: L10n.Settings.failedTitle
        }
    }

    var message: String {
        switch self {
        case .restored: L10n.Settings.restoredMessage
        case .restoreFailed: L10n.Settings.failedMessage
        }
    }
}
