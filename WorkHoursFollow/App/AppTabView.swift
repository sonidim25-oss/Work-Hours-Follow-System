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

    init(environment: AppEnvironment) {
        self.environment = environment
        _today = State(initialValue: environment.now())
    }

    var body: some View {
        TabView {
            OverviewView(environment: environment, today: today) {
                editorRoute = .create
            }
            .tabItem { Label("Overview", systemImage: "house.fill") }

            EntriesView(
                environment: environment,
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
        .task { restoreSettingsIfNeeded() }
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
    }

    private var effectiveSettings: AppSettings {
        if settings.count == 1,
           let settings = settings.first,
           AppEnvironment.settingsAreValid(settings, calendar: environment.calendar) {
            return settings
        }
        return AppEnvironment.defaultSettings(calendar: environment.calendar)
    }

    private func restoreSettingsIfNeeded() {
        if settings.count == 1,
           let settings = settings.first,
           AppEnvironment.settingsAreValid(settings, calendar: environment.calendar) {
            return
        }

        settings.forEach { modelContext.delete($0) }
        modelContext.insert(AppEnvironment.defaultSettings(calendar: environment.calendar))

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
