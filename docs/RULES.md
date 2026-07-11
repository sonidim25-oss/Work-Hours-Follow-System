# Work Hours Follow — Project Rules

## 1. Purpose of This File

This file defines the mandatory development rules for the **Work Hours Follow** iOS project.

These rules apply to:

- human developers;
- AI coding agents;
- code generation tools;
- code reviews;
- refactoring;
- testing;
- future feature additions.

The goal is to keep the app simple, predictable, testable, and aligned with the product requirements.

---

## 2. Product Principle

The app must remain focused on one core task:

> Manually enter total worked time for a date and immediately see estimated earnings for the correct two-week pay period.

Every feature must support at least one of these questions:

- How long did I work?
- How much did I earn?
- Which pay period does this workday belong to?
- When is the next payday?
- What did I earn in previous pay periods?

If a feature does not clearly support the core use case, it should not be added to the MVP.

---

## 3. Platform Rules

- Platform: iOS
- Primary device: iPhone
- Language: Swift
- UI framework: SwiftUI
- Persistence: SwiftData
- Minimum architecture: local-first
- Backend: not allowed in MVP
- User account: not allowed in MVP
- External API dependency: not allowed in MVP
- Internet connection: must not be required for core functionality

The app must remain fully usable offline.

---

## 4. Architecture Rules

Use a clear, lightweight architecture.

Recommended structure:

```text
App
├── Models
├── Views
├── ViewModels
├── Services
├── Utilities
├── Persistence
└── Tests
```

Suggested responsibilities:

```text
Models
- WorkEntry
- AppSettings
- PayPeriod
- PayPeriodStatus

Views
- CurrentPeriodView
- EntryEditorView
- HistoryView
- SettingsView

ViewModels
- CurrentPeriodViewModel
- EntryEditorViewModel
- HistoryViewModel
- SettingsViewModel

Services
- PayPeriodCalculator
- EarningsCalculator
- WorkEntryService

Utilities
- Date extensions
- Duration formatting
- Currency formatting
```

Rules:

- Views must not contain business logic.
- Pay-period calculations must not be implemented directly inside SwiftUI views.
- Earnings calculations must not be duplicated across the app.
- Date logic must exist in one dedicated service.
- Formatting logic must remain separate from calculation logic.
- SwiftData access should be isolated from UI when practical.
- Avoid unnecessary abstraction.
- Do not introduce complex patterns unless the project actually needs them.

---

## 5. Source of Truth

The following values must have one clear source of truth:

- work duration;
- hourly rate;
- anchor payday;
- pay-period length;
- pay-period start date;
- pay-period end date;
- estimated earnings.

Do not store multiple conflicting versions of the same value.

Examples:

- Store work duration as total minutes.
- Do not separately store hours, minutes, decimal hours, and formatted text.
- Store hourly rate as integer cents.
- Do not use a floating-point number as the primary money value.

Derived values should be calculated when needed.

---

## 6. Work Duration Rules

Work duration must be stored as:

```text
durationMinutes: Int
```

Example:

```text
10 hours 12 minutes = 612 minutes
```

Rules:

- Seconds are not supported.
- Minutes must be between 0 and 59 in the user input.
- Total duration must be greater than zero.
- Hours must be zero or greater.
- Future dates are not allowed in the MVP.
- One work entry per calendar date is allowed in the MVP.
- A date must be normalized using the user's current calendar and timezone.
- Duration must represent elapsed work time, not a clock time.

Do not use:

- Date for work duration;
- TimeInterval as the stored primary value;
- decimal hours as the stored primary value;
- a time-of-day picker for duration input.

---

## 7. Money Rules

Money must be stored and calculated using integer cents.

Example:

```text
$23.00/hour = 2300 cents/hour
```

Recommended model field:

```text
hourlyRateCents: Int
```

Calculation:

```text
earningsCents = durationMinutes × hourlyRateCents / 60
```

Rules:

- Never use `Double` as the source of truth for money.
- Currency values must be rounded consistently.
- Display values must use two decimal places.
- Currency code for MVP: CAD.
- Historical entries must preserve the hourly rate used when they were created.
- Changing the default hourly rate must affect new entries only.
- Existing historical entries must not silently change.

If rounding is required, use one documented rounding strategy throughout the project.

Recommended strategy:

```text
Round to the nearest cent.
```

---

## 8. Pay Period Rules

The pay period logic is critical and must be implemented exactly once.

Main rules:

- One pay period lasts 14 calendar days.
- A new pay period begins on Friday.
- The previous pay period ends on Thursday.
- Payday Friday belongs to the new pay period.
- Work completed on payday Friday is not included in the paycheck received that same day.
- One known payday Friday is stored as the anchor date.
- All previous and future periods are calculated in 14-day intervals from that anchor date.

Example:

```text
Anchor payday: Friday, July 10, 2026

Previous pay period:
Friday, June 26, 2026
through
Thursday, July 9, 2026

New pay period:
Friday, July 10, 2026
through
Thursday, July 23, 2026

Next payday:
Friday, July 24, 2026
```

Rules:

- Never hardcode a specific year or date in production logic.
- The anchor payday must be configurable.
- Pay-period calculations must use calendar dates, not raw second offsets.
- Daylight saving changes must not break period boundaries.
- Date comparisons must use start-of-day normalized dates.
- The period end date is inclusive.
- The next payday is the day after the current period ends.

---

## 9. Date and Timezone Rules

Use the user's local calendar and timezone.

Rules:

- Use `Calendar.current` or an injected calendar.
- Normalize stored work dates to start of day.
- Do not compare raw timestamps when only the calendar date matters.
- Do not assume UTC for pay-period grouping.
- Avoid adding fixed numbers of seconds for date arithmetic.
- Use calendar-based date addition.
- Tests must use a fixed calendar and timezone.

Recommended testing setup:

```text
Calendar: Gregorian
Timezone: America/Toronto
Locale: en_CA
```

---

## 10. Data Model Rules

### WorkEntry

Required fields:

```text
id: UUID
workDate: Date
durationMinutes: Int
hourlyRateCents: Int
createdAt: Date
updatedAt: Date
```

Rules:

- `workDate` identifies the calendar day worked.
- `durationMinutes` is the only stored duration value.
- `hourlyRateCents` preserves the rate at the time of entry.
- `createdAt` and `updatedAt` are audit timestamps.
- Do not store formatted strings in the model.

### AppSettings

Required fields:

```text
defaultHourlyRateCents: Int
currencyCode: String
anchorPayday: Date
payPeriodLengthDays: Int
```

MVP defaults:

```text
defaultHourlyRateCents = 2300
currencyCode = CAD
payPeriodLengthDays = 14
```

### PayPeriod

Pay periods should be derived unless storage is required later.

Derived values:

```text
startDate
endDate
payday
entries
totalMinutes
totalEarningsCents
status
```

Do not persist a pay period if it can be calculated reliably from settings and entries.

---

## 11. CRUD Rules

### Create

When creating a work entry:

- validate the date;
- validate hours and minutes;
- convert to total minutes;
- store the current default hourly rate;
- reject a future date;
- reject zero duration;
- detect an existing entry for the same date.

### Edit

When editing:

- update the changed fields only;
- refresh `updatedAt`;
- move the entry to the correct pay period automatically if the date changes;
- recalculate all affected totals;
- preserve the original hourly rate unless the user explicitly changes it.

### Delete

When deleting:

- require a confirmation action;
- remove only the selected entry;
- update totals immediately;
- never delete the entire pay period automatically.

### Duplicate Date

Only one entry per date is allowed in the MVP.

If an entry already exists:

- do not silently create a duplicate;
- present an edit or replace flow;
- keep the behavior consistent across the app.

---

## 12. UI Rules

The UI must prioritize speed and clarity.

Core flow:

```text
Open app → Select date → Enter hours and minutes → Save
```

Rules:

- The main screen must show the current pay period.
- The total worked time must be immediately visible.
- Estimated earnings must be immediately visible.
- The next payday must be visible.
- The Add Entry action must be prominent.
- Duration input must use separate hours and minutes controls.
- Do not use a start-time/end-time form.
- Do not show seconds.
- Avoid payroll terminology that may confuse users.
- Clearly label earnings as estimated gross earnings.

Recommended tabs:

```text
Current
History
Settings
```

Avoid:

- overcrowded dashboards;
- hidden essential actions;
- unnecessary onboarding;
- account creation;
- complex charts in MVP;
- decorative animations that slow down data entry.

---

## 13. Validation Rules

The app must validate all user input before saving.

Required validations:

```text
hours >= 0
minutes >= 0
minutes <= 59
durationMinutes > 0
workDate <= today
hourlyRateCents > 0
anchorPayday is a Friday
payPeriodLengthDays == 14 for MVP
```

Validation errors must:

- explain the problem clearly;
- appear near the affected input;
- not destroy entered data;
- not silently correct invalid values unless the correction is obvious and safe.

---

## 14. Formatting Rules

### Duration

Use:

```text
10h 12m
7h 0m
0h 45m
```

Do not display:

```text
10.2 hours
10:12 PM
612 minutes
```

unless specifically needed in a debug or detail view.

### Currency

Use localized CAD formatting.

Examples:

```text
$234.60
$1,806.27
```

### Dates

Use short, readable formats.

Examples:

```text
Jul 10, 2026
July 10 – July 23
Friday, July 10
```

Do not expose raw ISO date strings in the UI.

---

## 15. Testing Rules

Critical business logic must be covered by tests.

Minimum required unit tests:

### Duration Tests

- convert hours and minutes to total minutes;
- format total minutes correctly;
- reject minutes above 59;
- reject zero duration.

### Earnings Tests

- calculate earnings for full hours;
- calculate earnings for partial hours;
- round to nearest cent;
- preserve historical rates.

Required example:

```text
10h 12m at $23/hour = $234.60
```

### Pay Period Tests

- calculate the correct period from the anchor payday;
- assign payday Friday to the new period;
- assign Thursday before payday to the previous period;
- calculate previous periods;
- calculate future periods;
- handle month boundaries;
- handle year boundaries;
- handle daylight saving transitions.

Required example:

```text
Anchor payday: July 10, 2026

July 9, 2026 → previous period
July 10, 2026 → new period
July 23, 2026 → current period
July 24, 2026 → next period
```

### CRUD Tests

- create entry;
- edit entry;
- delete entry;
- reject duplicate date;
- move edited entry between periods.

Rules:

- Business logic must be testable without launching the UI.
- Tests must not depend on the current real date.
- Inject dates, calendars, and settings where practical.
- A feature is not complete if its critical logic has no tests.

---

## 16. Error Handling Rules

The app must fail safely.

Rules:

- Invalid input must never be saved.
- Persistence errors must be shown to the user.
- Failed saves must not create partial data.
- Failed deletes must not remove UI state prematurely.
- The app must not crash because of missing settings.
- If settings are missing, restore safe defaults.
- If the anchor date is invalid, require correction before calculating periods.

Do not ignore errors with empty `catch` blocks.

---

## 17. Swift and SwiftUI Code Rules

Use modern Swift conventions.

Rules:

- Prefer value types where appropriate.
- Use clear, descriptive names.
- Avoid force unwraps.
- Avoid force casts.
- Avoid deeply nested views.
- Extract reusable components when repetition becomes meaningful.
- Keep view bodies readable.
- Use `@MainActor` for UI state that must run on the main thread.
- Keep async work out of initializers.
- Use dependency injection for calculation services when useful.
- Avoid global mutable state.
- Avoid singleton services unless there is a strong reason.
- Add comments only when the reason is not obvious from the code.
- Do not comment every line.
- Prefer small focused functions.

---

## 18. AI Agent Rules

Any AI coding agent working on this project must follow these rules.

### Before Coding

The agent must:

1. Read `PROJECT_DESCRIPTION.md`.
2. Read `RULES.md`.
3. Identify the exact feature scope.
4. Inspect existing code before creating new files.
5. Reuse existing services and models where appropriate.
6. Avoid implementing out-of-scope features.

### During Coding

The agent must:

- preserve the existing architecture;
- avoid duplicating business logic;
- add or update tests;
- keep changes scoped to the task;
- avoid unrelated refactors;
- avoid adding dependencies unless necessary;
- avoid changing naming conventions without reason;
- avoid modifying project settings unless required;
- explain any architectural deviation.

### After Coding

The agent must:

- run relevant tests;
- verify the build;
- summarize changed files;
- mention known limitations;
- confirm that pay-period logic remains correct;
- avoid claiming success without verification.

---

## 19. Dependency Rules

The MVP should use Apple-native frameworks only where possible.

Allowed by default:

- SwiftUI
- SwiftData
- Foundation
- XCTest

Third-party packages are not allowed unless they solve a real problem that cannot be reasonably handled with native frameworks.

Before adding a dependency, document:

- why it is needed;
- what native alternative was considered;
- maintenance risk;
- license;
- impact on app size;
- impact on long-term support.

---

## 20. Security and Privacy Rules

The app stores personal work and earnings data.

Rules:

- Data stays on the device in MVP.
- Do not send analytics without explicit user consent.
- Do not send work records to external services.
- Do not require account creation.
- Do not log sensitive earnings data in production.
- Do not include personal work data in crash logs where avoidable.
- Use platform security defaults for local storage.
- Face ID protection may be added later but is not required for MVP.

---

## 21. Performance Rules

The app is small and should feel immediate.

Rules:

- Adding an entry must update totals instantly.
- History should load without noticeable delay.
- Do not perform unnecessary full-database scans.
- Avoid expensive calculations inside SwiftUI body rendering.
- Cache only when needed.
- Prefer correctness and simplicity over premature optimization.

---

## 22. Accessibility Rules

The app must remain usable with standard iOS accessibility features.

Rules:

- Support Dynamic Type.
- Provide accessible labels for icon-only buttons.
- Maintain sufficient text contrast.
- Do not communicate meaning with color alone.
- Buttons must have reasonable touch targets.
- Inputs must have visible labels.
- VoiceOver should clearly describe duration, date, and earnings.

---

## 23. Localization Rules

MVP language may be English only.

However:

- Do not hardcode user-facing strings throughout views.
- Keep strings centralized or prepared for localization.
- Use locale-aware date and currency formatting.
- Do not build formatting manually when Foundation provides a formatter.

Future localization should not require rewriting business logic.

---

## 24. Git Rules

Recommended branch naming:

```text
feature/add-work-entry
feature/pay-period-history
fix/payday-boundary
refactor/earnings-calculator
```

Commit rules:

- one logical change per commit;
- clear commit messages;
- no unrelated formatting changes;
- no generated files unless required;
- no secrets;
- no local environment files;
- no personal test data.

Recommended commit style:

```text
feat: add work entry creation
fix: assign payday Friday to new period
test: cover pay period boundary dates
refactor: extract earnings calculator
```

---

## 25. Definition of Done

A task is complete only when:

1. The feature matches `PROJECT_DESCRIPTION.md`.
2. The implementation follows `RULES.md`.
3. Business logic is not duplicated.
4. Relevant tests are added or updated.
5. Tests pass.
6. The project builds successfully.
7. No known crash is introduced.
8. The UI remains usable on iPhone.
9. Existing data remains compatible.
10. The change does not add out-of-scope functionality.
11. The agent or developer reports what changed.
12. Any limitation is explicitly documented.

---

## 26. Prohibited Changes Without Explicit Approval

Do not add or change the following without explicit approval:

- backend services;
- authentication;
- user accounts;
- subscriptions;
- advertisements;
- analytics SDKs;
- third-party tracking;
- Connecteam integration;
- automatic time import;
- tax calculations;
- overtime calculations;
- multiple jobs;
- multiple currencies;
- Android support;
- web support;
- cloud synchronization;
- major architecture replacement;
- large third-party dependencies;
- redesign of the pay-period rules.

---

## 27. Final Rule

When there is uncertainty, choose the implementation that is:

1. simpler;
2. easier to test;
3. easier to maintain;
4. aligned with the current MVP;
5. less likely to corrupt historical data;
6. consistent with the two-week Friday-to-Thursday pay-period logic.

Correct pay-period assignment and historical data integrity are more important than visual complexity or advanced features.
