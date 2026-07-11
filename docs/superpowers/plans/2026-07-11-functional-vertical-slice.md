# Functional Vertical Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a tested iOS app that saves work-duration entries locally and immediately shows correct totals for the active two-week pay period.

**Architecture:** Use one SwiftUI/SwiftData application target and one XCTest target. Keep calendar, earnings, validation, and entry-operation rules in small services independent of SwiftUI; views consume those services and persisted queries through explicit interfaces.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, Foundation, XCTest, Xcode 26; iOS 17 minimum; Apple frameworks only.

## Global Constraints

- Target iPhone on iOS 17 or later.
- Use SwiftUI, SwiftData, Foundation, and XCTest only; add no third-party packages.
- Keep all core behavior offline and local to the device.
- Store durations as integer minutes and money as integer cents.
- Use CAD and a default hourly rate of 2,300 cents.
- Use Friday, July 17, 2026 as the known payday anchor.
- Treat Friday, July 3 through Thursday, July 16, 2026 as the covered period for the July 17 paycheck.
- Work performed on July 17 starts the next period.
- Preserve each entry's creation-time hourly rate when editing it.
- Allow one entry per normalized calendar date and reject future dates.
- Use a four-tab shell: Overview, Entries, History, Settings.
- Match the supplied dark navy, cream, muted-gold, and red visual system.
- Keep History and Settings non-interactive foundations in this milestone.
- Use `Calendar.current` in production and an injected Gregorian `America/Toronto` calendar in tests.
- Use test-driven development and commit after every independently verified task.

## Planned File Map

```text
WorkHoursFollow.xcodeproj/
WorkHoursFollow/
├── App/
│   ├── WorkHoursFollowApp.swift          # SwiftData container and app entry
│   ├── AppTabView.swift                  # Four-tab navigation and editor routing
│   └── AppEnvironment.swift              # Calendar, clock, defaults
├── Models/
│   ├── WorkEntry.swift                   # Persisted work record
│   ├── AppSettings.swift                 # Persisted singleton settings
│   └── PayPeriod.swift                   # Derived period value
├── Services/
│   ├── DurationService.swift             # Duration conversion and validation
│   ├── EarningsCalculator.swift          # Integer-cent calculation
│   ├── PayPeriodCalculator.swift         # Calendar period derivation
│   ├── EntryValidator.swift              # Date, duration, duplicate checks
│   └── EntryStore.swift                  # SwiftData CRUD boundary
├── Utilities/
│   └── AppFormatters.swift               # Localized duration, currency, dates
├── DesignSystem/
│   ├── AppColors.swift
│   ├── AppTypography.swift
│   ├── AppSpacing.swift
│   └── AppRadius.swift
├── Components/
│   ├── PrimaryButton.swift
│   ├── SummaryCard.swift
│   └── WorkEntryCard.swift
└── Features/
    ├── Overview/OverviewView.swift
    ├── Entries/EntriesView.swift
    ├── EntryEditor/EntryEditorView.swift
    ├── History/HistoryPlaceholderView.swift
    └── Settings/SettingsPlaceholderView.swift
WorkHoursFollowTests/
├── TestCalendar.swift
├── DurationServiceTests.swift
├── EarningsCalculatorTests.swift
├── PayPeriodCalculatorTests.swift
├── EntryValidatorTests.swift
└── EntryStoreTests.swift
```

---

### Task 1: Create the Native Project and Smoke-Test Harness

**Files:**
- Create: `WorkHoursFollow.xcodeproj/project.pbxproj`
- Create: `WorkHoursFollow.xcodeproj/xcshareddata/xcschemes/WorkHoursFollow.xcscheme`
- Create: `WorkHoursFollow/App/WorkHoursFollowApp.swift`
- Create: `WorkHoursFollow/App/AppTabView.swift`
- Create: `WorkHoursFollowTests/ProjectSmokeTests.swift`
- Modify: `.gitignore`

**Interfaces:**
- Produces: Xcode scheme `WorkHoursFollow`, app bundle identifier `com.kseniiakozak.WorkHoursFollow`, test bundle `WorkHoursFollowTests`, and iOS 17 deployment target.

- [ ] **Step 1: Create the Xcode project from the iOS App template**

Create a project named `WorkHoursFollow` with SwiftUI, Swift, SwiftData, XCTest, no organization prefix, deployment target iOS 17.0, automatic Info.plist generation, and source/test folders at the paths above. Share the `WorkHoursFollow` scheme. The application target must compile all files under `WorkHoursFollow`; the test target must compile all files under `WorkHoursFollowTests` and depend on the app target.

The target settings must include:

```text
PRODUCT_BUNDLE_IDENTIFIER = com.kseniiakozak.WorkHoursFollow
IPHONEOS_DEPLOYMENT_TARGET = 17.0
SWIFT_VERSION = 6.0
GENERATE_INFOPLIST_FILE = YES
TARGETED_DEVICE_FAMILY = 1
CODE_SIGN_STYLE = Automatic
```

- [ ] **Step 2: Write the initial smoke test**

```swift
import XCTest
@testable import WorkHoursFollow

final class ProjectSmokeTests: XCTestCase {
    func testApplicationModuleLoads() {
        XCTAssertEqual(AppTab.overview.title, "Overview")
    }
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run:

```bash
xcodebuild test -project WorkHoursFollow.xcodeproj -scheme WorkHoursFollow -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO
```

Expected: FAIL because `AppTab` is not defined.

- [ ] **Step 4: Add the minimal application shell**

```swift
// WorkHoursFollow/App/AppTabView.swift
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

// WorkHoursFollow/App/WorkHoursFollowApp.swift
import SwiftUI

@main
struct WorkHoursFollowApp: App {
    var body: some Scene {
        WindowGroup { AppTabView() }
    }
}
```

Add `.build/`, `xcuserdata/`, and `*.xcuserstate` to `.gitignore`.

- [ ] **Step 5: Run the smoke test**

Run the Task 1 `xcodebuild test` command.

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 6: Commit**

```bash
git add .gitignore WorkHoursFollow.xcodeproj WorkHoursFollow WorkHoursFollowTests
git commit -m "chore: scaffold iOS application"
```

---

### Task 2: Implement Duration and Earnings Rules

**Files:**
- Create: `WorkHoursFollow/Services/DurationService.swift`
- Create: `WorkHoursFollow/Services/EarningsCalculator.swift`
- Create: `WorkHoursFollowTests/DurationServiceTests.swift`
- Create: `WorkHoursFollowTests/EarningsCalculatorTests.swift`
- Delete: `WorkHoursFollowTests/ProjectSmokeTests.swift`

**Interfaces:**
- Produces: `DurationService.totalMinutes(hours:minutes:) throws -> Int`
- Produces: `EarningsCalculator.earningsCents(durationMinutes:hourlyRateCents:) -> Int`
- Produces: `DurationValidationError` cases `.negativeHours`, `.invalidMinutes`, `.zeroDuration`

- [ ] **Step 1: Write failing duration tests**

```swift
import XCTest
@testable import WorkHoursFollow

final class DurationServiceTests: XCTestCase {
    func testConvertsTenHoursTwelveMinutes() throws {
        XCTAssertEqual(try DurationService.totalMinutes(hours: 10, minutes: 12), 612)
    }

    func testRejectsNegativeHours() {
        XCTAssertThrowsError(try DurationService.totalMinutes(hours: -1, minutes: 0)) {
            XCTAssertEqual($0 as? DurationValidationError, .negativeHours)
        }
    }

    func testRejectsMinutesOutsideRange() {
        XCTAssertThrowsError(try DurationService.totalMinutes(hours: 1, minutes: 60)) {
            XCTAssertEqual($0 as? DurationValidationError, .invalidMinutes)
        }
    }

    func testRejectsZeroDuration() {
        XCTAssertThrowsError(try DurationService.totalMinutes(hours: 0, minutes: 0)) {
            XCTAssertEqual($0 as? DurationValidationError, .zeroDuration)
        }
    }
}
```

- [ ] **Step 2: Run duration tests and verify failure**

Run:

```bash
xcodebuild test -project WorkHoursFollow.xcodeproj -scheme WorkHoursFollow -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WorkHoursFollowTests/DurationServiceTests -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO
```

Expected: FAIL because `DurationService` is undefined.

- [ ] **Step 3: Implement duration validation**

```swift
import Foundation

enum DurationValidationError: Error, Equatable {
    case negativeHours
    case invalidMinutes
    case zeroDuration
}

enum DurationService {
    static func totalMinutes(hours: Int, minutes: Int) throws -> Int {
        guard hours >= 0 else { throw DurationValidationError.negativeHours }
        guard (0...59).contains(minutes) else { throw DurationValidationError.invalidMinutes }
        let total = hours * 60 + minutes
        guard total > 0 else { throw DurationValidationError.zeroDuration }
        return total
    }
}
```

- [ ] **Step 4: Run duration tests and verify success**

Run the Task 2 duration command.

Expected: `4 tests, 0 failures`.

- [ ] **Step 5: Write failing earnings tests**

```swift
import XCTest
@testable import WorkHoursFollow

final class EarningsCalculatorTests: XCTestCase {
    func testRequiredExample() {
        XCTAssertEqual(EarningsCalculator.earningsCents(durationMinutes: 612, hourlyRateCents: 2300), 23_460)
    }

    func testRemainderBelowHalfRoundsDown() {
        XCTAssertEqual(EarningsCalculator.earningsCents(durationMinutes: 1, hourlyRateCents: 29), 0)
    }

    func testHalfCentRoundsUp() {
        XCTAssertEqual(EarningsCalculator.earningsCents(durationMinutes: 1, hourlyRateCents: 30), 1)
    }
}
```

- [ ] **Step 6: Run earnings tests and verify failure**

Run the Task 2 test command with `-only-testing:WorkHoursFollowTests/EarningsCalculatorTests`.

Expected: FAIL because `EarningsCalculator` is undefined.

- [ ] **Step 7: Implement integer-cent earnings**

```swift
enum EarningsCalculator {
    static func earningsCents(durationMinutes: Int, hourlyRateCents: Int) -> Int {
        precondition(durationMinutes >= 0 && hourlyRateCents >= 0)
        let numerator = durationMinutes * hourlyRateCents
        let quotient = numerator / 60
        let remainder = numerator % 60
        return quotient + (remainder >= 30 ? 1 : 0)
    }
}
```

- [ ] **Step 8: Run both suites and commit**

Run the full test command. Expected: all tests pass.

```bash
git add WorkHoursFollow/Services WorkHoursFollowTests
git commit -m "feat: add duration and earnings rules"
```

---

### Task 3: Derive Pay Periods from the Payday Anchor

**Files:**
- Create: `WorkHoursFollow/Models/PayPeriod.swift`
- Create: `WorkHoursFollow/Services/PayPeriodCalculator.swift`
- Create: `WorkHoursFollowTests/TestCalendar.swift`
- Create: `WorkHoursFollowTests/PayPeriodCalculatorTests.swift`

**Interfaces:**
- Produces: `PayPeriod(startDate:endDate:payday:)`
- Produces: `PayPeriodCalculator(calendar:).period(containing:anchorPayday:) throws -> PayPeriod`
- Produces: `PayPeriodCalculationError.anchorIsNotFriday`

- [ ] **Step 1: Add deterministic calendar helpers and failing boundary tests**

```swift
// WorkHoursFollowTests/TestCalendar.swift
import Foundation

enum TestCalendar {
    static var toronto: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Toronto")!
        calendar.locale = Locale(identifier: "en_CA")
        return calendar
    }

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        toronto.date(from: DateComponents(year: year, month: month, day: day))!
    }
}

// WorkHoursFollowTests/PayPeriodCalculatorTests.swift
import XCTest
@testable import WorkHoursFollow

final class PayPeriodCalculatorTests: XCTestCase {
    private let calculator = PayPeriodCalculator(calendar: TestCalendar.toronto)
    private let anchor = TestCalendar.date(2026, 7, 17)

    func testJulyTenFallsInJulyThreeThroughSixteenPeriod() throws {
        let period = try calculator.period(containing: TestCalendar.date(2026, 7, 10), anchorPayday: anchor)
        XCTAssertEqual(period.startDate, TestCalendar.date(2026, 7, 3))
        XCTAssertEqual(period.endDate, TestCalendar.date(2026, 7, 16))
        XCTAssertEqual(period.payday, anchor)
    }

    func testJulySixteenRemainsInEndingPeriod() throws {
        XCTAssertEqual(try calculator.period(containing: TestCalendar.date(2026, 7, 16), anchorPayday: anchor).startDate, TestCalendar.date(2026, 7, 3))
    }

    func testJulySeventeenStartsNextPeriod() throws {
        let period = try calculator.period(containing: anchor, anchorPayday: anchor)
        XCTAssertEqual(period.startDate, anchor)
        XCTAssertEqual(period.endDate, TestCalendar.date(2026, 7, 30))
        XCTAssertEqual(period.payday, TestCalendar.date(2026, 7, 31))
    }

    func testWorksAcrossYearBoundary() throws {
        let period = try calculator.period(containing: TestCalendar.date(2027, 1, 1), anchorPayday: anchor)
        XCTAssertTrue(period.contains(TestCalendar.date(2027, 1, 1), calendar: TestCalendar.toronto))
    }

    func testRejectsNonFridayAnchor() {
        XCTAssertThrowsError(try calculator.period(containing: anchor, anchorPayday: TestCalendar.date(2026, 7, 16)))
    }
}
```

- [ ] **Step 2: Run tests and verify failure**

Run Task 2's command with `-only-testing:WorkHoursFollowTests/PayPeriodCalculatorTests`.

Expected: FAIL because `PayPeriodCalculator` and `PayPeriod` are undefined.

- [ ] **Step 3: Implement the derived period model**

```swift
import Foundation

struct PayPeriod: Equatable, Sendable {
    let startDate: Date
    let endDate: Date
    let payday: Date

    func contains(_ date: Date, calendar: Calendar) -> Bool {
        let day = calendar.startOfDay(for: date)
        return day >= startDate && day <= endDate
    }
}
```

- [ ] **Step 4: Implement calendar-based derivation**

```swift
import Foundation

enum PayPeriodCalculationError: Error, Equatable {
    case anchorIsNotFriday
    case calendarCalculationFailed
}

struct PayPeriodCalculator: Sendable {
    let calendar: Calendar

    func period(containing date: Date, anchorPayday: Date) throws -> PayPeriod {
        let anchor = calendar.startOfDay(for: anchorPayday)
        guard calendar.component(.weekday, from: anchor) == 6 else {
            throw PayPeriodCalculationError.anchorIsNotFriday
        }
        let day = calendar.startOfDay(for: date)
        guard let delta = calendar.dateComponents([.day], from: anchor, to: day).day else {
            throw PayPeriodCalculationError.calendarCalculationFailed
        }
        let index = delta >= 0 ? delta / 14 : -((-delta + 13) / 14)
        guard
            let start = calendar.date(byAdding: .day, value: index * 14, to: anchor),
            let end = calendar.date(byAdding: .day, value: 13, to: start),
            let payday = calendar.date(byAdding: .day, value: 14, to: start)
        else {
            throw PayPeriodCalculationError.calendarCalculationFailed
        }
        return PayPeriod(startDate: start, endDate: end, payday: payday)
    }
}
```

- [ ] **Step 5: Add a daylight-saving assertion**

Add a test using a Friday anchor before the March 2026 Toronto transition and assert the returned start/end remain local start-of-day and 13 calendar days apart.

```swift
func testUsesCalendarDaysAcrossDaylightSaving() throws {
    let anchor = TestCalendar.date(2026, 3, 6)
    let period = try calculator.period(containing: TestCalendar.date(2026, 3, 15), anchorPayday: anchor)
    XCTAssertEqual(period.startDate, anchor)
    XCTAssertEqual(period.endDate, TestCalendar.date(2026, 3, 19))
}
```

- [ ] **Step 6: Run tests and commit**

Expected: all `PayPeriodCalculatorTests` pass.

```bash
git add WorkHoursFollow/Models WorkHoursFollow/Services/PayPeriodCalculator.swift WorkHoursFollowTests
git commit -m "feat: derive biweekly pay periods"
```

---

### Task 4: Add SwiftData Models and Default Environment

**Files:**
- Create: `WorkHoursFollow/Models/WorkEntry.swift`
- Create: `WorkHoursFollow/Models/AppSettings.swift`
- Create: `WorkHoursFollow/App/AppEnvironment.swift`
- Modify: `WorkHoursFollow/App/WorkHoursFollowApp.swift`
- Create: `WorkHoursFollowTests/AppEnvironmentTests.swift`

**Interfaces:**
- Produces: SwiftData `WorkEntry` and `AppSettings` models.
- Produces: `AppEnvironment.defaultSettings(calendar:) -> AppSettings`
- Produces: `AppEnvironment.now: () -> Date` and `calendar: Calendar`.

- [ ] **Step 1: Write failing default-settings test**

```swift
import XCTest
@testable import WorkHoursFollow

final class AppEnvironmentTests: XCTestCase {
    func testDefaultSettingsMatchApprovedValues() {
        let settings = AppEnvironment.defaultSettings(calendar: TestCalendar.toronto)
        XCTAssertEqual(settings.defaultHourlyRateCents, 2300)
        XCTAssertEqual(settings.currencyCode, "CAD")
        XCTAssertEqual(settings.anchorPayday, TestCalendar.date(2026, 7, 17))
        XCTAssertEqual(settings.payPeriodLengthDays, 14)
    }
}
```

- [ ] **Step 2: Run test and verify failure**

Expected: FAIL because `AppEnvironment` is undefined.

- [ ] **Step 3: Implement models and defaults**

```swift
// Models/WorkEntry.swift
import Foundation
import SwiftData

@Model
final class WorkEntry {
    @Attribute(.unique) var id: UUID
    var workDate: Date
    var durationMinutes: Int
    var hourlyRateCents: Int
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), workDate: Date, durationMinutes: Int, hourlyRateCents: Int, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.workDate = workDate
        self.durationMinutes = durationMinutes
        self.hourlyRateCents = hourlyRateCents
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var earningsCents: Int {
        EarningsCalculator.earningsCents(durationMinutes: durationMinutes, hourlyRateCents: hourlyRateCents)
    }
}

// Models/AppSettings.swift
import Foundation
import SwiftData

@Model
final class AppSettings {
    var defaultHourlyRateCents: Int
    var currencyCode: String
    var anchorPayday: Date
    var payPeriodLengthDays: Int

    init(defaultHourlyRateCents: Int, currencyCode: String, anchorPayday: Date, payPeriodLengthDays: Int) {
        self.defaultHourlyRateCents = defaultHourlyRateCents
        self.currencyCode = currencyCode
        self.anchorPayday = anchorPayday
        self.payPeriodLengthDays = payPeriodLengthDays
    }
}
```

```swift
// App/AppEnvironment.swift
import Foundation

struct AppEnvironment: Sendable {
    var calendar: Calendar
    var now: @Sendable () -> Date

    static let live = AppEnvironment(calendar: .current, now: Date.init)

    static func defaultSettings(calendar: Calendar) -> AppSettings {
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 7, day: 17))!
        return AppSettings(defaultHourlyRateCents: 2300, currencyCode: "CAD", anchorPayday: anchor, payPeriodLengthDays: 14)
    }
}
```

- [ ] **Step 4: Attach the SwiftData container**

```swift
import SwiftData
import SwiftUI

@main
struct WorkHoursFollowApp: App {
    var body: some Scene {
        WindowGroup { AppTabView(environment: .live) }
            .modelContainer(for: [WorkEntry.self, AppSettings.self])
    }
}
```

Update `AppTabView` to accept `let environment: AppEnvironment`.

- [ ] **Step 5: Run full tests and commit**

Expected: all tests pass.

```bash
git add WorkHoursFollow WorkHoursFollowTests
git commit -m "feat: add local work entry models"
```

---

### Task 5: Implement Validated SwiftData CRUD

**Files:**
- Create: `WorkHoursFollow/Services/EntryValidator.swift`
- Create: `WorkHoursFollow/Services/EntryStore.swift`
- Create: `WorkHoursFollowTests/EntryValidatorTests.swift`
- Create: `WorkHoursFollowTests/EntryStoreTests.swift`

**Interfaces:**
- Produces: `EntryValidationError.futureDate` and `.duplicateDate(UUID)`.
- Produces: `EntryStore.create(date:durationMinutes:hourlyRateCents:now:) throws -> WorkEntry`.
- Produces: `EntryStore.update(_:date:durationMinutes:now:) throws` preserving the stored rate.
- Produces: `EntryStore.delete(_:) throws` and `entries(in:) throws -> [WorkEntry]`.

- [ ] **Step 1: Write failing validator tests**

Create an in-memory `ModelContainer` for `WorkEntry` and `AppSettings`. Assert that July 12 is rejected when `now` is July 11 and that two timestamps on July 10 are treated as the same normalized date.

```swift
func testRejectsFutureDate() throws {
    let validator = EntryValidator(calendar: TestCalendar.toronto)
    XCTAssertThrowsError(try validator.validate(date: TestCalendar.date(2026, 7, 12), now: TestCalendar.date(2026, 7, 11), existingEntries: [], excluding: nil)) {
        XCTAssertEqual($0 as? EntryValidationError, .futureDate)
    }
}
```

- [ ] **Step 2: Implement normalized-date validation**

```swift
import Foundation

enum EntryValidationError: Error, Equatable {
    case futureDate
    case duplicateDate(UUID)
}

struct EntryValidator {
    let calendar: Calendar

    func validate(date: Date, now: Date, existingEntries: [WorkEntry], excluding id: UUID?) throws {
        let day = calendar.startOfDay(for: date)
        guard day <= calendar.startOfDay(for: now) else { throw EntryValidationError.futureDate }
        if let duplicate = existingEntries.first(where: { $0.id != id && calendar.isDate($0.workDate, inSameDayAs: day) }) {
            throw EntryValidationError.duplicateDate(duplicate.id)
        }
    }
}
```

- [ ] **Step 3: Run validator tests**

Expected: future and duplicate-date tests pass.

- [ ] **Step 4: Write failing CRUD tests**

Use an in-memory container and verify create normalizes the date, update changes date/duration but preserves `hourlyRateCents`, period queries sort newest first, delete removes the entry, and a duplicate creation throws.

```swift
func testUpdatePreservesHistoricalRate() throws {
    let entry = try store.create(date: TestCalendar.date(2026, 7, 10), durationMinutes: 60, hourlyRateCents: 2300, now: TestCalendar.date(2026, 7, 11))
    try store.update(entry, date: TestCalendar.date(2026, 7, 9), durationMinutes: 90, now: TestCalendar.date(2026, 7, 11))
    XCTAssertEqual(entry.hourlyRateCents, 2300)
    XCTAssertEqual(entry.durationMinutes, 90)
}
```

- [ ] **Step 5: Implement the store boundary**

```swift
import Foundation
import SwiftData

@MainActor
struct EntryStore {
    let context: ModelContext
    let calendar: Calendar

    private var validator: EntryValidator { EntryValidator(calendar: calendar) }

    func allEntries() throws -> [WorkEntry] {
        try context.fetch(FetchDescriptor<WorkEntry>(sortBy: [SortDescriptor(\.workDate, order: .reverse)]))
    }

    func create(date: Date, durationMinutes: Int, hourlyRateCents: Int, now: Date) throws -> WorkEntry {
        let existing = try allEntries()
        try validator.validate(date: date, now: now, existingEntries: existing, excluding: nil)
        let normalized = calendar.startOfDay(for: date)
        let entry = WorkEntry(workDate: normalized, durationMinutes: durationMinutes, hourlyRateCents: hourlyRateCents, createdAt: now, updatedAt: now)
        context.insert(entry)
        try context.save()
        return entry
    }

    func update(_ entry: WorkEntry, date: Date, durationMinutes: Int, now: Date) throws {
        try validator.validate(date: date, now: now, existingEntries: try allEntries(), excluding: entry.id)
        entry.workDate = calendar.startOfDay(for: date)
        entry.durationMinutes = durationMinutes
        entry.updatedAt = now
        try context.save()
    }

    func delete(_ entry: WorkEntry) throws {
        context.delete(entry)
        try context.save()
    }

    func entries(in period: PayPeriod) throws -> [WorkEntry] {
        try allEntries().filter { period.contains($0.workDate, calendar: calendar) }
    }
}
```

- [ ] **Step 6: Run full tests and commit**

Expected: all CRUD and prior domain tests pass.

```bash
git add WorkHoursFollow/Services WorkHoursFollowTests
git commit -m "feat: add validated entry persistence"
```

---

### Task 6: Build Formatting, Design Tokens, and Shared Cards

**Files:**
- Create: `WorkHoursFollow/Utilities/AppFormatters.swift`
- Create: `WorkHoursFollow/DesignSystem/AppColors.swift`
- Create: `WorkHoursFollow/DesignSystem/AppTypography.swift`
- Create: `WorkHoursFollow/DesignSystem/AppSpacing.swift`
- Create: `WorkHoursFollow/DesignSystem/AppRadius.swift`
- Create: `WorkHoursFollow/Components/PrimaryButton.swift`
- Create: `WorkHoursFollow/Components/SummaryCard.swift`
- Create: `WorkHoursFollow/Components/WorkEntryCard.swift`
- Create: `WorkHoursFollowTests/AppFormattersTests.swift`

**Interfaces:**
- Produces: `AppFormatters.duration(_:)`, `.currency(cents:code:)`, `.periodRange(_:)`, and `.entryDate(_:)`.
- Produces: reusable `PrimaryButton`, `SummaryCard`, and `WorkEntryCard`.

- [ ] **Step 1: Write failing formatter tests**

Assert `612 -> "10h 12m"`, `23_460 CAD -> "$234.60"` under `en_CA`, and the approved July period range includes both July 3 and July 16.

- [ ] **Step 2: Implement deterministic formatters**

```swift
import Foundation

enum AppFormatters {
    static func duration(_ minutes: Int) -> String { "\(minutes / 60)h \(minutes % 60)m" }

    static func currency(cents: Int, code: String = "CAD", locale: Locale = Locale(identifier: "en_CA")) -> String {
        let amount = Decimal(cents) / Decimal(100)
        return amount.formatted(.currency(code: code).locale(locale))
    }

    static func periodRange(_ period: PayPeriod, locale: Locale = Locale(identifier: "en_CA")) -> String {
        period.startDate.formatted(.dateTime.month(.abbreviated).day().year().locale(locale)) + " – " + period.endDate.formatted(.dateTime.month(.abbreviated).day().year().locale(locale))
    }

    static func entryDate(_ date: Date, locale: Locale = Locale(identifier: "en_CA")) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().locale(locale))
    }
}
```

Do not convert cents through `Double`.

- [ ] **Step 3: Add exact semantic tokens**

```swift
import SwiftUI

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255, blue: Double(hex & 0xff) / 255, opacity: opacity)
    }
}

enum AppColors {
    static let background = Color(hex: 0x061321)
    static let backgroundElevated = Color(hex: 0x0E1B2E)
    static let surfaceDark = Color(hex: 0x16273F)
    static let surfaceCream = Color(hex: 0xF4EDE1)
    static let textLight = Color(hex: 0xF4EDE1)
    static let textDark = Color(hex: 0x142033)
    static let secondary = Color(hex: 0x8D94A1)
    static let gold = Color(hex: 0xC9A66B)
    static let accent = Color(hex: 0xD8332A)
}

enum AppSpacing { static let xs: CGFloat = 8; static let sm: CGFloat = 12; static let md: CGFloat = 16; static let lg: CGFloat = 24; static let xl: CGFloat = 32 }
enum AppRadius { static let medium: CGFloat = 14; static let card: CGFloat = 16 }
enum AppTypography { static let title = Font.system(size: 34, weight: .semibold, design: .serif); static let metric = Font.system(size: 38, weight: .semibold, design: .serif) }
```

- [ ] **Step 4: Implement shared components**

Create components with typed inputs, 44-point minimum targets, semantic colors, tabular metrics, accessibility labels, and no business logic. `PrimaryButton` has a 52-point red body; `SummaryCard` receives formatted total-time and earnings strings; `WorkEntryCard` receives a `WorkEntry` and tap action.

- [ ] **Step 5: Run tests, build, and commit**

Expected: formatter tests pass and `xcodebuild build ... -destination 'generic/platform=iOS Simulator'` succeeds.

```bash
git add WorkHoursFollow WorkHoursFollowTests
git commit -m "feat: add work hours design system"
```

---

### Task 7: Implement the Add/Edit Entry Sheet

**Files:**
- Create: `WorkHoursFollow/Features/EntryEditor/EntryEditorView.swift`
- Modify: `WorkHoursFollow/App/AppTabView.swift`
- Create: `WorkHoursFollowTests/EntryEditorStateTests.swift`

**Interfaces:**
- Produces: `EntryEditorState` with `date`, `hours`, `minutes`, `earningsCents`, `canSave`, and validation copy.
- Consumes: `DurationService`, `EarningsCalculator`, `EntryStore`, `AppEnvironment`, and `AppSettings`.

- [ ] **Step 1: Write failing editor-state tests**

Test that zero duration disables Save, 10h12m previews 23,460 cents, a future date disables Save, and editing initializes from an existing entry while retaining its rate.

- [ ] **Step 2: Implement editor state**

```swift
struct EntryEditorState {
    var date: Date
    var hours: Int
    var minutes: Int
    let hourlyRateCents: Int

    var durationMinutes: Int? { try? DurationService.totalMinutes(hours: hours, minutes: minutes) }
    var earningsCents: Int { EarningsCalculator.earningsCents(durationMinutes: durationMinutes ?? 0, hourlyRateCents: hourlyRateCents) }

    func canSave(now: Date, calendar: Calendar) -> Bool {
        durationMinutes != nil && calendar.startOfDay(for: date) <= calendar.startOfDay(for: now)
    }
}
```

- [ ] **Step 3: Run state tests**

Expected: all editor-state tests pass.

- [ ] **Step 4: Build the sheet UI**

Implement a `NavigationStack` sheet with Cancel, contextual Add/Edit title, Save, a graphical date picker capped at `now`, separate wheel pickers for hours `0...24` and minutes `0...59`, and a live rate/earnings panel. Use the existing entry's rate during edit and settings' rate during creation.

On Save, call `EntryStore.create` or `update`. Keep the sheet open on errors. Map `.duplicateDate(id)` to an alert offering **Edit Existing Entry** and **Cancel**; the edit action loads the matching persisted entry. Map other persistence errors to a plain-language alert without discarding state.

- [ ] **Step 5: Wire editor routing**

Add `@State private var editorRoute: EditorRoute?` to `AppTabView`; present `.sheet(item:)` from Add buttons and entry taps. Ensure routes distinguish `.create` and `.edit(WorkEntry)`.

- [ ] **Step 6: Build, test, and commit**

Expected: full unit suite passes and simulator build succeeds.

```bash
git add WorkHoursFollow WorkHoursFollowTests
git commit -m "feat: add work entry editor"
```

---

### Task 8: Connect Overview and Entries to Live Data

**Files:**
- Create: `WorkHoursFollow/Features/Overview/OverviewView.swift`
- Create: `WorkHoursFollow/Features/Entries/EntriesView.swift`
- Create: `WorkHoursFollow/Features/History/HistoryPlaceholderView.swift`
- Create: `WorkHoursFollow/Features/Settings/SettingsPlaceholderView.swift`
- Modify: `WorkHoursFollow/App/AppTabView.swift`
- Create: `WorkHoursFollowTests/PeriodSummaryTests.swift`

**Interfaces:**
- Produces: four-tab live UI.
- Consumes: SwiftData `@Query` entries/settings, `PayPeriodCalculator`, `EarningsCalculator`, shared formatters/components, and editor routes.

- [ ] **Step 1: Write failing summary tests**

Introduce a pure `PeriodSummary(entries:)` value and test that entries outside July 3–16 are excluded, durations sum, and earnings sum the individually rounded entry earnings.

```swift
func testSumsOnlyIncludedEntries() {
    let entries = [
        WorkEntry(workDate: TestCalendar.date(2026, 7, 10), durationMinutes: 612, hourlyRateCents: 2300, createdAt: .distantPast, updatedAt: .distantPast),
        WorkEntry(workDate: TestCalendar.date(2026, 7, 11), durationMinutes: 60, hourlyRateCents: 2300, createdAt: .distantPast, updatedAt: .distantPast)
    ]
    let summary = PeriodSummary(entries: entries)
    XCTAssertEqual(summary.totalMinutes, 672)
    XCTAssertEqual(summary.totalEarningsCents, 25_760)
}
```

- [ ] **Step 2: Implement `PeriodSummary` in `PayPeriod.swift`**

```swift
struct PeriodSummary {
    let totalMinutes: Int
    let totalEarningsCents: Int

    init(entries: [WorkEntry]) {
        totalMinutes = entries.reduce(0) { $0 + $1.durationMinutes }
        totalEarningsCents = entries.reduce(0) { $0 + $1.earningsCents }
    }
}
```

- [ ] **Step 3: Implement Overview**

Query entries and settings, restore defaults when settings are absent or invalid, derive today's period from `environment.now()`, filter included entries, and render the approved date range, next payday, elapsed-day text, total duration, total earnings, and Add button. Empty totals must remain `0h 0m` and `$0.00`.

Elapsed days are clamped to `1...14` and calculated with calendar date components from period start to today's normalized date, plus one.

- [ ] **Step 4: Implement Entries**

Render current-period entries newest first with `WorkEntryCard`. Tapping opens edit. Swipe Delete presents a confirmation dialog; only remove the row after `EntryStore.delete` succeeds. Show an alert and retain the row on failure. The empty state keeps the Add button visible.

- [ ] **Step 5: Complete four-tab navigation**

```swift
TabView {
    OverviewView(environment: environment, onAdd: { editorRoute = .create })
        .tabItem { Label("Overview", systemImage: "house.fill") }
    EntriesView(environment: environment, onAdd: { editorRoute = .create }, onEdit: { editorRoute = .edit($0) })
        .tabItem { Label("Entries", systemImage: "list.bullet.rectangle") }
    HistoryPlaceholderView()
        .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
    SettingsPlaceholderView()
        .tabItem { Label("Settings", systemImage: "gearshape.fill") }
}
.tint(AppColors.accent)
```

Placeholder screens state only that the features will be added in a later milestone and expose no fake export, backup, or settings actions.

- [ ] **Step 6: Run tests, build, and commit**

Expected: full tests pass; app builds for generic simulator.

```bash
git add WorkHoursFollow WorkHoursFollowTests
git commit -m "feat: connect current period screens"
```

---

### Task 9: Verify Persistence, Accessibility, and Visual Match

**Files:**
- Modify: implemented SwiftUI files only where verification identifies defects.
- Modify: `docs/TODO.md`
- Create: `docs/verification/2026-07-11-functional-vertical-slice.md`

**Interfaces:**
- Consumes: completed application.
- Produces: repeatable verification record and updated sprint checklist.

- [ ] **Step 1: Run the complete automated suite**

```bash
xcodebuild test -project WorkHoursFollow.xcodeproj -scheme WorkHoursFollow -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO
```

Expected: `** TEST SUCCEEDED **` with zero failures.

- [ ] **Step 2: Build the application independently**

```bash
xcodebuild build -project WorkHoursFollow.xcodeproj -scheme WorkHoursFollow -destination 'generic/platform=iOS Simulator' -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Perform simulator acceptance flow**

Launch on an available iPhone Simulator. With the simulator date fixed in a debug-only injected environment or preview at July 11, 2026:

1. Confirm Overview shows July 3–16 and payday July 17.
2. Add July 10 with 10h12m and confirm `$234.60`.
3. Add a second earlier day and confirm summary totals.
4. Attempt July 12 while the injected current day is July 11 and confirm Save is disabled.
5. Attempt a duplicate July 10 and confirm Edit Existing Entry/Cancel.
6. Edit July 10's duration and verify totals.
7. Delete it, cancel once, then confirm deletion and verify totals.
8. Relaunch the app and verify the remaining record persists.

- [ ] **Step 4: Perform visual and accessibility checks**

Compare Overview, Entries, and Entry Editor to `docs/design kit/Design_Board.png`, `02_Entries.png`, and `03_Add_Edit_Entry.png`. Check an iPhone SE-sized simulator and a current Pro-sized simulator. Verify extra-large Dynamic Type, VoiceOver labels for icon-only controls, Reduce Motion behavior, wrapping rather than clipping, 44-point targets, color-independent error/status text, and keyboard/picker clearance.

- [ ] **Step 5: Correct any verified defects and rerun Steps 1–4**

Keep fixes limited to observed acceptance, accessibility, persistence, spacing, typography, color, and component-proportion failures. Every correction must retain green tests.

- [ ] **Step 6: Record evidence and update the sprint**

In the verification document, record the Xcode version, simulator devices, commands and results, tested acceptance flow, screenshots inspected, accessibility checks, and any remaining limitation. In `docs/TODO.md`, mark navigation, Current Period Screen, Add Entry, Edit Entry, Delete Entry, and Tests complete; leave History and Settings incomplete.

- [ ] **Step 7: Final commit**

```bash
git add WorkHoursFollow WorkHoursFollowTests docs/TODO.md docs/verification
git commit -m "test: verify functional vertical slice"
```

## Final Verification Gate

Before claiming completion, run `git status --short`, the full test command, and the generic simulator build command from Task 9. The work is complete only when the tree contains no unintended changes, all tests pass, the build succeeds, persistence survives relaunch, and the documented July 16/July 17 boundary behaves correctly.
