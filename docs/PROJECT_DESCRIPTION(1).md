# Work Hours Follow

## Project Description

### 1. Overview

**Work Hours Follow** is a simple iOS application for manually tracking completed work hours and estimating gross earnings.

The app is designed for users who already use another service, such as Connecteam, to record shifts but need a faster and clearer way to:

- enter the total duration of each completed workday;
- see total hours for the current pay period;
- calculate estimated gross earnings;
- correct or delete previously entered records;
- add missed workdays later;
- keep a history of completed pay periods.

The application does not replace a time-clock system. It acts as a personal work-hours and earnings calculator.

---

## 2. Main Problem

Connecteam shows the duration of individual shifts, but calculating total hours and expected earnings for a two-week pay period is inconvenient.

The user currently has to:

1. open Connecteam;
2. check the total duration of each shift;
3. manually add hours and minutes;
4. calculate earnings using the hourly rate;
5. determine which shifts belong to the current paycheck.

This creates unnecessary calculation work and increases the chance of mistakes.

---

## 3. Solution

After finishing a shift, the user opens Connecteam and checks the total worked time.

The user then opens Work Hours Follow and manually enters:

- the work date;
- total hours;
- total minutes.

Example:

```text
10:12
```

This means:

```text
10 hours and 12 minutes
```

The app does not require:

- shift start time;
- shift end time;
- seconds;
- automatic Connecteam integration.

After saving the entry, the app immediately updates:

- total worked time for the current pay period;
- estimated gross earnings;
- list of recorded workdays;
- progress toward the end of the current pay period.

---

## 4. Target Platform

- iOS
- iPhone-first interface
- Local-first data storage
- No account required for the MVP
- No backend required for the MVP

---

## 5. Default User Configuration

Initial default settings:

```text
Hourly rate: $23.00 CAD
Pay frequency: Every 2 weeks
Pay period start day: Friday
Pay period length: 14 days
Currency: CAD
```

The hourly rate should be editable in Settings because it may change in the future.

---

## 6. Core User Flow

### Daily Work Entry

1. The user finishes a shift.
2. The user checks the total shift duration in Connecteam.
3. The user opens Work Hours Follow.
4. The user selects the date.
5. The user enters total worked hours and minutes.
6. The user saves the entry.
7. The app recalculates current totals and earnings.

Example:

```text
Date: July 10, 2026
Duration: 10 hours 12 minutes
Hourly rate: $23.00
Estimated earnings: $234.60
```

Calculation:

```text
10 hours 12 minutes
= 10 + 12 / 60
= 10.2 hours

10.2 × $23.00
= $234.60
```

Internally, calculations should use total minutes to avoid floating-point errors.

```text
10 hours 12 minutes = 612 minutes
Hourly rate per minute = 23 / 60
Earnings = 612 × 23 / 60
```

---

## 7. Pay Period Logic

### Main Rule

A pay period lasts 14 calendar days.

Each new pay period begins on every second Friday.

The Friday on which the paycheck is received belongs to the new pay period, not the paycheck that was just received.

Therefore:

- the previous pay period ends on Thursday at 11:59 PM;
- the new pay period starts on Friday at 12:00 AM;
- work completed on payday Friday is counted toward the next paycheck.

### Example

Paycheck received:

```text
Friday, July 10, 2026
```

The paycheck covers work completed during:

```text
Friday, June 26, 2026
through
Thursday, July 9, 2026
```

Work completed on:

```text
Friday, July 10, 2026
```

belongs to the next pay period.

The next pay period is:

```text
Friday, July 10, 2026
through
Thursday, July 23, 2026
```

The next paycheck is expected on:

```text
Friday, July 24, 2026
```

### Anchor Date

The app must store one known payday Friday as an anchor date.

Example:

```text
Anchor payday: Friday, July 10, 2026
```

Using this date, the app can calculate all previous and future pay periods in 14-day intervals.

---

## 8. Current Pay Period Screen

The main screen should show the current active pay period.

### Summary

- current pay period date range;
- next payday;
- total worked hours and minutes;
- estimated gross earnings;
- number of recorded workdays;
- days remaining in the pay period.

Example:

```text
Current Pay Period
July 10 – July 23

Total Time
32h 48m

Estimated Earnings
$754.40

Next Payday
July 24
```

### Workday List

Each workday entry should display:

- date;
- total duration;
- estimated earnings for that day;
- edit action;
- delete action.

Example:

```text
Monday, July 13
6h 24m
$147.20
```

---

## 9. Add Work Entry

The user can create an entry for today or for a previous date.

### Required Fields

- work date;
- hours;
- minutes.

### Input Rules

- hours must be zero or greater;
- minutes must be between 0 and 59;
- total duration must be greater than zero;
- seconds are not supported;
- future dates should not be allowed by default;
- only one work entry per date should exist in the MVP.

If the user enters time for a date that already has an entry, the app should offer to edit or replace the existing record.

### Suggested Input Interface

Use separate numeric inputs or wheel pickers:

```text
Hours: 10
Minutes: 12
```

Avoid using a clock-style time picker because the value represents duration, not time of day.

---

## 10. Edit Work Entry

The user can edit:

- work date;
- hours;
- minutes.

After editing, the app must automatically:

- move the entry to the correct pay period if the date changes;
- recalculate daily earnings;
- recalculate pay-period totals;
- update historical totals if an old entry was edited.

---

## 11. Delete Work Entry

The user can delete any work entry.

Before deletion, the app should display a confirmation message.

Example:

```text
Delete this work entry?

July 13, 2026
6h 24m
```

After deletion, all affected totals must update immediately.

---

## 12. Missed Entry Support

The user can add time for a previous date.

Example:

The user forgets to enter Monday's shift and remembers on Tuesday.

The user should be able to:

1. tap Add Entry;
2. select Monday;
3. enter the total worked duration;
4. save it.

The app must assign the record to the correct pay period based on the selected date.

---

## 13. Earnings Calculation

### Gross Earnings

The app calculates estimated earnings before taxes and deductions.

Formula:

```text
Gross earnings = total worked minutes × hourly rate / 60
```

Example:

```text
Worked time: 7h 14m
Total minutes: 434
Hourly rate: $23.00

434 × 23 / 60 = $166.37
```

Displayed money values should be rounded to two decimal places.

### Important Disclaimer

The app provides an estimate only.

It does not calculate:

- income tax;
- CPP;
- Employment Insurance;
- overtime;
- vacation pay;
- bonuses;
- unpaid breaks;
- employer corrections;
- payroll deductions.

These may be added later, but they are outside the MVP scope.

---

## 14. Pay Period History

Completed pay periods must remain available in the app.

The app must not delete previous records when a new pay period begins.

Each historical period should display:

- period start date;
- period end date;
- payday;
- total worked time;
- total estimated gross earnings;
- number of recorded workdays;
- list of individual entries.

Example:

```text
June 26 – July 9
Paid July 10

Total Time
78h 32m

Estimated Gross Earnings
$1,806.27
```

Possible status values:

- Current
- Upcoming
- Completed
- Paid

For the MVP, status can be derived automatically from dates. A manual Paid toggle is optional.

---

## 15. Settings

The Settings screen should include:

### Hourly Rate

Default:

```text
$23.00 CAD/hour
```

The user can change the hourly rate.

A rate change should not silently modify historical calculations.

Recommended behavior:

- each work entry stores the hourly rate used when it was created;
- changing the default hourly rate affects new entries only;
- historical entries retain their original rate.

### Pay Schedule

The user should configure:

- one known payday Friday;
- pay period frequency: every 2 weeks;
- pay period start day: Friday.

For the MVP, the frequency and weekday may remain fixed, while the anchor payday is editable.

### Currency

Default:

```text
CAD
```

Only CAD is required for the MVP.

---

## 16. Data Model

### WorkEntry

```text
id: UUID
workDate: Date
durationMinutes: Int
hourlyRateCents: Int
createdAt: Date
updatedAt: Date
```

Derived values:

```text
hours = durationMinutes / 60
remainingMinutes = durationMinutes % 60
earningsCents = durationMinutes × hourlyRateCents / 60
```

### AppSettings

```text
defaultHourlyRateCents: Int
currencyCode: String
anchorPayday: Date
payPeriodLengthDays: Int
payPeriodStartWeekday: Friday
```

### PayPeriod

A pay period can be calculated dynamically and does not necessarily need to be stored as a separate database object.

Derived properties:

```text
startDate: Date
endDate: Date
payday: Date
entries: [WorkEntry]
totalMinutes: Int
totalEarningsCents: Int
status: PayPeriodStatus
```

---

## 17. Recommended Local Storage

For the iOS MVP:

- SwiftData
- local device storage
- no login;
- no cloud backend;
- no external API.

Possible future addition:

- iCloud synchronization through CloudKit.

---

## 18. Main Screens

### 1. Current Period

Shows:

- current pay-period range;
- total hours;
- estimated earnings;
- next payday;
- workday list;
- Add Entry button.

### 2. Add/Edit Entry

Contains:

- date selector;
- hours input;
- minutes input;
- calculated earnings preview;
- Save button.

### 3. History

Shows:

- previous pay periods;
- total hours for each period;
- estimated earnings;
- expandable workday details.

### 4. Settings

Contains:

- default hourly rate;
- anchor payday;
- currency;
- app information.

---

## 19. MVP Features

The first version must include:

1. Add a work entry.
2. Select today or a previous date.
3. Enter total hours and minutes.
4. Edit an existing entry.
5. Delete an existing entry.
6. Calculate daily gross earnings.
7. Calculate total pay-period hours.
8. Calculate total pay-period gross earnings.
9. Automatically assign entries to 14-day pay periods.
10. Start each new period on payday Friday.
11. Exclude payday Friday from the paycheck received that day.
12. Preserve previous pay periods in history.
13. Configure the hourly rate.
14. Configure one known payday as the schedule anchor.
15. Store all data locally.

---

## 20. Out of Scope for MVP

The first version will not include:

- Connecteam integration;
- automatic shift import;
- user accounts;
- cloud backend;
- Android version;
- web version;
- taxes and deductions;
- overtime rules;
- break tracking;
- GPS tracking;
- shift start and end times;
- seconds;
- multiple jobs;
- multiple hourly rates within the same day;
- payroll submission;
- employer access;
- PDF reports;
- CSV export;
- notifications.

---

## 21. Future Features

Possible future additions:

- overtime calculation;
- tax and deduction estimates;
- multiple jobs;
- different hourly rates;
- unpaid break support;
- notes for each workday;
- calendar view;
- weekly summaries;
- payday notifications;
- reminders to enter missing workdays;
- CSV export;
- PDF reports;
- iCloud synchronization;
- Face ID protection;
- widgets;
- Apple Watch support;
- automatic Connecteam import if an API becomes available;
- comparison between estimated and actual paycheck amounts.

---

## 22. Acceptance Criteria

The MVP is considered functional when:

1. The user can enter `10 hours 12 minutes` for a selected date.
2. The app stores the duration as `612 minutes`.
3. At `$23/hour`, the app displays `$234.60`.
4. The user can edit the entry and totals update immediately.
5. The user can delete the entry and totals update immediately.
6. The user can add an entry for yesterday or another previous date.
7. Each entry is assigned to the correct two-week pay period.
8. A shift entered on payday Friday belongs to the next pay period.
9. A pay period ends on the Thursday before payday.
10. Previous pay periods remain visible in History.
11. Closing and reopening the app does not remove saved data.

---

## 23. Product Principle

The application should remain simple.

The main interaction should take only a few seconds:

```text
Open app → Select date → Enter hours and minutes → Save
```

The user should immediately understand:

```text
How long have I worked?
How much have I earned?
When does the current pay period end?
Which paycheck will include this workday?
```

The product should prioritize clarity, speed, and accurate pay-period grouping over advanced payroll functionality.
