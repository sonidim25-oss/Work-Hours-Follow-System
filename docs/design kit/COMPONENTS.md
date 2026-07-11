# Work Hours Follow — Screen Specifications

## 1. Overview Screen

Reference:

```text
References/01_Overview.png
```

### Structure

1. Large app title: `Work Hours Follow`
2. Current pay-period label
3. Date range
4. Small progress text such as `5 of 14 days`
5. Large cream summary card
6. Red primary button
7. Bottom tab bar

### Summary card

Contains:

- label: `Total Hours`;
- large duration value;
- label: `Total Earned`;
- large CAD currency value.

The duration and earnings are the strongest visual elements.

### Primary action

Label:

```text
Add Work Time
```

Style:

- full width;
- red background;
- cream text;
- plus icon;
- medium corner radius;
- minimum height 52 points.

### Empty state

When no entries exist:

- show `0h 0m`;
- show `$0.00`;
- retain the primary Add button;
- optionally show one quiet explanatory sentence below the period date.

---

## 2. Entries Screen

Reference:

```text
References/02_Entries.png
```

### Structure

1. Screen title: `Entries`
2. Current pay-period section
3. Period date range
4. Vertical list of work-entry cards
5. Secondary cream Add button
6. Bottom tab bar

### Work-entry card

Cream background.

Left side:

- abbreviated weekday and date;
- optional full date in accessibility label.

Right side:

- duration;
- earnings in gold;
- disclosure chevron.

Example:

```text
Fri, Jul 4            6h 24m
                      $147.20
```

### Interactions

- tap card: open Edit Entry;
- swipe leading/trailing: optional Edit and Delete;
- Delete must show confirmation;
- cards are sorted newest first within the current period.

---

## 3. Add/Edit Entry Screen

Reference:

```text
References/03_Add_Edit_Entry.png
```

### Presentation

Use a full-screen sheet or pushed editor.

Top navigation:

- left: `Cancel`;
- centered title: `Add Work Time` or `Edit Work Time`;
- right: `Save`.

Cancel and Save use the accent color.

### Fields

#### Date row

Dark elevated card with:

- label: `Date`;
- selected formatted date;
- calendar icon;
- tap opens native date picker.

#### Duration picker

Header:

```text
Total Time Worked
```

Use two vertically scrolling wheels:

- hours;
- minutes.

Minutes must contain values `00–59`.

Selected values are large and cream. Neighboring values are muted.

Display unit labels:

- hours;
- minutes.

### Earnings preview

Dark summary card:

```text
Rate:   $23.00 / hour
Earned: $166.37
```

Rate and earned values use gold.

### Validation

Disable Save when:

- duration is zero;
- date is in the future;
- input is otherwise invalid.

If the date already has an entry, show a clear replacement/edit warning rather than creating a silent duplicate.

---

## 4. History Screen

Reference:

```text
References/04_History.png
```

### Structure

1. Screen title: `History`
2. List of completed pay-period cards
3. Bottom tab bar

### Pay-period card

Cream background.

Top row:

- date range;
- total duration aligned right.

Bottom row:

- total gross earnings;
- status badge aligned right.

Example:

```text
Jun 20 – Jul 3, 2026       80h 36m
$1,853.88                      Paid
```

### Status badge

- `Paid`: muted green background;
- `Current`: red or gold;
- `Upcoming`: muted gray.

Status text must remain visible independently of color.

### Interaction

Tap card to open a pay-period detail screen with individual work entries.

---

## 5. Settings Screen

Reference:

```text
References/05_Settings.png
```

### Structure

1. Screen title: `Settings`
2. Grouped dark sections
3. Bottom tab bar

### Sections

#### Work

- Hourly Rate
- Payday
- Next Payday

#### Data

- Export History
- Backup & Restore
- Clear All Data

#### About

- Help & Support
- About Work Hours Follow
- Version

### Row style

- dark rounded container;
- cream or white primary text;
- muted trailing value;
- chevron;
- subtle divider.

`Clear All Data` uses red text and requires a destructive confirmation flow.

---

## 6. Pay-Period Detail Screen

Not displayed as a full primary mockup but required for History navigation.

### Structure

- period date range;
- status;
- total hours;
- total earnings;
- list of included work entries.

Use the same visual language as Entries and Overview.

---

## 7. Required UI States

Each main screen must support:

- loading/persistence initialization;
- empty state;
- populated state;
- validation error;
- save failure;
- delete confirmation;
- destructive reset confirmation;
- Dynamic Type;
- light accessibility contrast testing, even though the product remains visually dark.

No network loading state is required for MVP.
