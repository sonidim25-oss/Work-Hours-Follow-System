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
    let environment: AppEnvironment
    @Query(sort: \WorkEntry.workDate, order: .reverse) private var entries: [WorkEntry]
    @Query private var settings: [AppSettings]
    @State private var editorRoute: EditorRoute?

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                Text(AppTab.overview.title)
                    .font(AppTypography.title)

                PrimaryButton(title: "Add Work Time", systemImage: "plus") {
                    editorRoute = .create
                }

                ForEach(entries, id: \.id) { entry in
                    WorkEntryCard(entry: entry) {
                        editorRoute = .edit(entry)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(AppColors.textLight)
        .background(AppColors.background.ignoresSafeArea())
        .sheet(item: $editorRoute) { route in
            EntryEditorView(
                route: route,
                environment: environment,
                settings: settings.first ?? AppEnvironment.defaultSettings(calendar: environment.calendar)
            )
        }
    }
}
