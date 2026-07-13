import SwiftData
import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case overview, entries, history, settings

    var title: String {
        switch self {
        case .overview: "Overview"
        case .entries: "Entries"
        case .history: "History"
        case .settings: "Settings"
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
            .tabItem { Label("Overview", systemImage: "house.fill") }

            EntriesView(
                environment: environment,
                settings: effectiveSettings,
                today: today,
                onAdd: { editorRoute = .create },
                onEdit: { editorRoute = .edit($0) }
            )
            .tabItem { Label("Entries", systemImage: "list.bullet.rectangle") }

            HistoryPlaceholderView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            SettingsPlaceholderView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
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
                dismissButton: .default(Text("OK"))
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
        case .restored: "Safe Defaults Restored"
        case .restoreFailed: "Settings Need Attention"
        }
    }

    var message: String {
        switch self {
        case .restored:
            "Missing or invalid settings were replaced with the documented $23 CAD biweekly defaults."
        case .restoreFailed:
            "The app couldn’t save replacement settings. Safe defaults will be used for this session."
        }
    }
}
