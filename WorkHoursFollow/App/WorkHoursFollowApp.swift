import SwiftData
import SwiftUI

@main
struct WorkHoursFollowApp: App {
    var body: some Scene {
        WindowGroup { AppTabView(environment: .live) }
            .modelContainer(for: [WorkEntry.self, AppSettings.self])
    }
}
