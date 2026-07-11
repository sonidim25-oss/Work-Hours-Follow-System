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
    var body: some View {
        Text(AppTab.overview.title)
    }
}
