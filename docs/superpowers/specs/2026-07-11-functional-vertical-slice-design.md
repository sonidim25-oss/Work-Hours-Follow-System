# Work Hours Follow Functional Vertical Slice Design

**Date:** July 11, 2026  
**Status:** Approved for implementation planning

## Objective

Build the first functional milestone of Work Hours Follow as a native, local-first iPhone app. The milestone must prove the critical workflow end to end:

```text
Open app → Add work date and duration → Save locally → See updated period totals
```

The milestone prioritizes correct pay-period assignment, earnings calculations, historical rate integrity, and durable local storage. It also establishes the approved four-tab navigation and visual system without attempting the entire MVP at once.

## Product Decisions

- Platform: iPhone, iOS 17 or later.
- Frameworks: SwiftUI, SwiftData, Foundation, and XCTest only.
- Navigation: Overview, Entries, History, and Settings tabs.
- Architecture: one application target and one unit-test target.
- Storage: local SwiftData storage with no account, backend, or network dependency.
- Initial hourly rate: $23.00 CAD per hour.
- Known payday anchor: Friday, July 17, 2026.
- Initial active work period: Friday, July 3 through Thursday, July 16, 2026.
- Work performed on Friday, July 17 belongs to the next pay period.
- First launch opens directly into the app with documented defaults; no onboarding is required.

## Milestone Scope

### Included

- Xcode project, application target, and unit-test target.
- Four-tab application shell.
- Shared design tokens and foundational components needed by implemented screens.
- Functional Overview screen.
- Functional current-period Entries screen.
- Add and Edit Work Entry sheet.
- Confirmed deletion of work entries.
- SwiftData models and local persistence.
- Duration validation and formatting.
- Earnings calculation and formatting.
- Pay-period derivation from the known payday anchor.
- Empty, populated, validation-error, persistence-error, and duplicate-date states.
- Navigation foundations for History and Settings.
- Automated tests for critical business rules.
- Simulator verification against the supplied design references.

### Excluded

- Completed-period History functionality and pay-period detail.
- Functional Settings editing beyond the safe default-settings foundation.
- Export, backup, restore, or cloud synchronization.
- Taxes, deductions, overtime, breaks, bonuses, or multiple jobs.
- Notifications, accounts, analytics, and Connecteam integration.
- Third-party packages.

History and Settings must not present excluded features as working actions. Their tab roots may use a clearly unfinished, non-interactive foundation until later milestones.

## Architecture

The project uses a focused application target plus a unit-test target. Code is organized by responsibility while avoiding package-level modularity that the MVP does not need.

```text
WorkHoursFollow
├── App
├── Models
├── Services
├── Persistence
├── Features
│   ├── Overview
│   ├── Entries
│   ├── EntryEditor
│   ├── History
│   └── Settings
├── DesignSystem
├── Components
└── Utilities
```

SwiftUI views present state and forward user actions. They do not calculate earnings or pay periods. Services own business rules and remain testable without launching the UI. Calendar, timezone, and the current date are injectable wherever they affect results.

The production app uses the user's local calendar and timezone. Deterministic tests use a Gregorian calendar, the `America/Toronto` timezone, and fixed dates.

## Domain Model

### WorkEntry

Persist these source-of-truth fields:

```text
id: UUID
workDate: Date
durationMinutes: Int
hourlyRateCents: Int
createdAt: Date
updatedAt: Date
```

`workDate` is normalized to the start of its calendar day. Duration, formatted strings, earnings, and period membership are derived rather than redundantly stored. Each entry snapshots the default hourly rate that was active at creation so later rate changes do not alter history.

Only one entry may exist per normalized calendar date.

### AppSettings

Persist one settings record with:

```text
defaultHourlyRateCents: Int = 2300
currencyCode: String = "CAD"
anchorPayday: Date = July 17, 2026
payPeriodLengthDays: Int = 14
```

If settings are missing or the anchor date is not a Friday, the application restores these documented safe defaults and informs the user. Editable schedule settings belong to a later milestone.

### PayPeriod

`PayPeriod` is a derived value, not a persisted model. It contains:

```text
startDate
endDate
payday
status
entries
totalMinutes
totalEarningsCents
```

The known payday is also the start of a new work period. Therefore the period that produces the July 17 paycheck runs from July 3 through July 16, and the next period begins July 17.

## Business Rules

### Duration

- Store total elapsed work time as integer minutes.
- Accept hours of zero or greater and minutes from 0 through 59.
- Reject a total duration of zero.
- Do not support seconds or time-of-day input.
- Do not allow future work dates.

### Earnings

Calculate daily earnings using integer arithmetic:

```text
unrounded numerator = durationMinutes × hourlyRateCents
earningsCents = numerator divided by 60, rounded to the nearest cent
```

All inputs are non-negative. A remainder of 30 or more rounds upward; a smaller remainder rounds downward. This makes the required example deterministic:

```text
612 minutes × 2300 cents / 60 = 23460 cents = $234.60
```

Period earnings are the sum of each entry's individually calculated earnings cents. This preserves the displayed daily amounts and historical rate snapshots.

### Pay periods

- Each period contains 14 calendar days.
- Periods use calendar-based date addition, never fixed second offsets.
- The period start is inclusive and falls on Friday.
- The period end is inclusive and falls on Thursday.
- Payday is the Friday immediately after the covered period ends and is simultaneously the first day of the next period.
- Periods before and after the anchor are derived in 14-day intervals.
- Calendar-date comparisons use normalized dates.

## User Experience

### Application shell

Use a persistent four-tab structure:

1. Overview
2. Entries
3. History
4. Settings

The active tab uses the red accent; inactive items use muted gray. Primary screens preserve standard safe-area and native tab behavior.

### Overview

Overview displays:

- current pay-period date range;
- next payday;
- elapsed-day progress within the 14-day period;
- total recorded hours and minutes;
- estimated gross earnings;
- prominent Add Work Time action.

When there are no entries, totals remain visible as `0h 0m` and `$0.00`, and the Add action remains available.

### Entries

Entries lists records in the current period, newest first. Each card shows the date, duration, estimated daily earnings, and disclosure affordance. Tapping a card opens Edit Work Time. Deletion requires explicit confirmation and updates totals only after persistence succeeds.

### Add and Edit Work Entry

Present the editor as a native sheet with Cancel, a contextual title, and Save.

- Date defaults to today and may be changed to today or an earlier date.
- Duration uses separate hours and minutes controls.
- Estimated earnings update immediately as duration changes.
- Save is disabled for zero duration or a future date.
- Editing may change the date and therefore move an entry to another period.
- Editing preserves the entry's original hourly-rate snapshot.

If a selected date already contains another entry, saving does not replace it. The app offers **Edit Existing Entry** or **Cancel**. Choosing Edit Existing Entry dismisses or transitions from the attempted new entry into the existing record's editor without losing that persisted record.

## Data Flow

When a user saves a valid entry:

1. Normalize the selected date with the injected calendar.
2. Validate the date and duration.
3. Query for an entry with the same normalized date, excluding the entry currently being edited.
4. For creation, snapshot the current default hourly rate.
5. For editing, retain the existing hourly-rate snapshot.
6. Insert or update the entry and save the SwiftData context.
7. Dismiss the editor only after persistence succeeds.
8. Let the persisted query refresh Overview totals and the Entries list.

Period totals are derived from entries whose normalized dates fall within the inclusive period boundaries.

## Error Handling

- Validation messages appear near the affected input and preserve entered data.
- A duplicate date never creates or silently replaces an entry.
- A failed save leaves the editor open and presents a clear alert.
- A failed delete leaves the entry visible and presents a clear alert.
- Missing or invalid settings are replaced with the documented safe defaults and the user is informed.
- Errors must not be swallowed with empty `catch` blocks.

## Visual and Accessibility Requirements

Follow the supplied dark-mode-first references and semantic tokens:

- deep navy application background;
- warm cream primary cards;
- muted gold for earnings and supporting emphasis;
- red for primary actions, active navigation, and destructive emphasis;
- serif typography for titles and major totals;
- SF Pro for controls, body content, and navigation;
- 24-point screen padding, 16-point card padding, and consistent card radii;
- no gradients, glass effects, charts, or decorative animation.

Native behavior and accessibility take priority over literal pixel copying. Support Dynamic Type, VoiceOver, Reduce Motion, readable contrast, wrapping at large text sizes, tabular metric values, and minimum 44-by-44-point interaction targets.

## Testing Strategy

### Unit tests

Cover at minimum:

- hours and minutes conversion;
- `10h 12m` becoming 612 minutes;
- 612 minutes at $23/hour producing $234.60;
- nearest-cent rounding on both sides of the half-cent boundary;
- July 3–16 derived from the July 17 payday anchor;
- July 16 assigned to the ending period;
- July 17 assigned to the next period;
- dates and periods before and after the anchor;
- month, year, and daylight-saving boundaries;
- zero-duration and future-date rejection;
- duplicate normalized-date rejection;
- create, edit, move-between-periods, and delete behavior;
- total recalculation after mutations;
- preservation of historical hourly-rate snapshots.

### Build and simulator verification

- Build the application with Xcode.
- Run the complete unit-test suite.
- Launch on a representative iPhone Simulator.
- Exercise empty and populated states.
- Add an earlier workday in the July 3–16 period and confirm totals.
- Relaunch and confirm persistence.
- Compare Overview, Entries, and Entry Editor with the supplied image references.
- Check content on a smaller iPhone and with a larger Dynamic Type setting.

## Acceptance Criteria

The milestone is complete when:

1. The app launches into the four-tab shell without onboarding.
2. Overview correctly shows the active period and next payday for a fixed July 2026 test date.
3. A user can add a positive duration for today or a previous date.
4. The entry persists across application relaunches.
5. Overview and Entries update immediately after creation, editing, or deletion.
6. Duplicate dates and future dates cannot be saved.
7. Earnings use integer cents and the documented rounding rule.
8. July 16 and July 17 fall on the correct sides of the payday boundary.
9. Historical rate snapshots are preserved.
10. The app builds, all tests pass, and the implemented screens are verified in Simulator.

## Follow-on Milestones

After this vertical slice is verified, subsequent specs can cover:

1. Completed-period History and pay-period details.
2. Editable hourly rate and payday settings.
3. Accessibility and visual-polish completion across all screens.

Export, backup, cloud sync, and other explicitly excluded product features require separate approval before design or implementation.
