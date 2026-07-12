import SwiftData
import SwiftUI

@main
struct WorkHoursFollowApp: App {
    private let environment: AppEnvironment

    init() {
#if DEBUG
        environment = AppEnvironment.debugLaunchOverride() ?? .live
#else
        environment = .live
#endif
    }

    var body: some Scene {
        WindowGroup { AppTabView(environment: environment) }
            .modelContainer(for: [WorkEntry.self, AppSettings.self])
    }
}
