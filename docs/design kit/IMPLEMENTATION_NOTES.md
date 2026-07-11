# Work Hours Follow — Component Specifications

## PrimaryButton

Purpose: main task completion.

```swift
PrimaryButton(
    title: "Add Work Time",
    systemImage: "plus",
    action: {}
)
```

Rules:

- red background;
- cream foreground;
- full-width by default;
- height: 52;
- corner radius: 12–14;
- semibold body text;
- pressed opacity or subtle scale feedback;
- disabled state uses lower opacity.

---

## SecondaryButton

Purpose: non-primary creation or navigation.

Rules:

- cream background;
- dark text;
- optional icon;
- height: 48–52;
- full width where used below lists.

---

## OutlineButton

Purpose: Edit, Cancel, or low-priority actions.

Rules:

- transparent background;
- one-point muted-gold or gray border;
- cream or gold label;
- red border and label for destructive outline actions.

---

## SummaryCard

Purpose: display current total time and earnings.

Rules:

- cream surface;
- dark text;
- 16-point internal padding;
- 16-point radius;
- labels use body/caption;
- values use large serif type;
- vertical separation between metrics.

---

## WorkEntryCard

Properties:

```text
date
durationMinutes
earningsCents
onTap
```

Rules:

- cream surface;
- 14–16 radius;
- date on the left;
- duration top-right;
- earnings bottom-right in gold;
- disclosure chevron;
- minimum height around 70 points.

---

## PayPeriodCard

Properties:

```text
dateRange
totalDuration
totalEarnings
status
```

Rules:

- cream surface;
- two-row layout;
- status badge;
- tap opens detail;
- minimum height around 84 points.

---

## SettingsSection

Purpose: grouped settings rows.

Rules:

- title displayed above group in gold or muted cream;
- rows share one dark rounded container;
- subtle internal dividers;
- first and last rows respect container corner shape.

---

## SettingsRow

Properties:

```text
title
trailingValue
systemImage?
role?
action
```

Rules:

- minimum height: 48;
- label on left;
- value and chevron on right;
- destructive role uses red;
- support accessibility value.

---

## StatusBadge

Supported states:

```text
paid
current
upcoming
```

Rules:

- compact horizontal padding;
- small capsule shape;
- small caption text;
- never rely on color alone.

---

## DurationPicker

Use a custom SwiftUI picker composition or native wheel pickers.

Columns:

- hours;
- minutes.

Rules:

- minute range: 0...59;
- selected row centered;
- adjacent values remain visible;
- large serif selected value;
- use tabular numbers;
- do not represent duration as a `Date`.

---

## AppTabBar

Tabs:

```text
Overview
Entries
History
Settings
```

Rules:

- dark background;
- active icon and label in red;
- inactive content in muted gray;
- stable height;
- safe-area aware;
- use standard `TabView` where possible, styled to match the mockup.
