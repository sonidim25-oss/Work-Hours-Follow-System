import XCTest
@testable import WorkHoursFollow

final class ProjectSmokeTests: XCTestCase {
    func testApplicationModuleLoads() {
        XCTAssertEqual(AppTab.overview.title, "Overview")
    }
}
