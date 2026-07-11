# Work Hours Follow — SwiftUI Implementation Notes

## 1. Design Token Structure

Create reusable semantic files:

```text
DesignSystem/
├── AppColors.swift
├── AppTypography.swift
├── AppSpacing.swift
├── AppRadius.swift
├── AppIcons.swift
└── ViewModifiers.swift
```

Views must use tokens rather than repeated literal values.

---

## 2. Suggested Component Structure

```text
Components/
├── Buttons/
│   ├── PrimaryButton.swift
│   ├── SecondaryButton.swift
│   └── OutlineButton.swift
├── Cards/
│   ├── SummaryCard.swift
│   ├── WorkEntryCard.swift
│   └── PayPeriodCard.swift
├── Settings/
│   ├── SettingsSection.swift
│   └── SettingsRow.swift
├── DurationPicker.swift
├── StatusBadge.swift
└── AppTabBar.swift
```

---

## 3. Screen Structure

```text
Features/
├── Overview/
├── Entries/
├── EntryEditor/
├── History/
├── PayPeriodDetail/
└── Settings/
```

Do not implement all screens in one large SwiftUI file.

---

## 4. Reference-Driven Workflow for Codex

For every screen task, the agent must:

1. Read `PROJECT_DESCRIPTION.md`.
2. Read `RULES.md`.
3. Read `Design/DESIGN_SYSTEM.md`.
4. Read the relevant section in `Design/SCREEN_SPECS.md`.
5. Inspect the matching image in `Design/References`.
6. Build reusable components before duplicating visual structures.
7. Run the app or preview at representative iPhone sizes.
8. Compare the result against the reference.
9. Correct spacing, typography, colors, and component proportions.
10. Verify Dynamic Type and accessibility labels.

---

## 5. Visual Verification Checklist

Before declaring a screen complete, verify:

- background token matches;
- horizontal padding is 24 points;
- cream and dark surfaces are correctly assigned;
- serif typography is used only for display hierarchy;
- values use tabular numbers;
- card radii are consistent;
- active tab is red;
- earnings use muted gold;
- actions have at least 44-point touch targets;
- content does not clip on smaller iPhones;
- content remains readable with larger text;
- keyboard does not obscure editor actions.

---

## 6. Exactness Policy

The reference image is authoritative for visual direction, but it is not a mathematical layout file.

Priority order:

1. business correctness;
2. accessibility;
3. native iOS interaction quality;
4. visual match;
5. decorative detail.

When the reference conflicts with an iOS usability convention, preserve the visual style while using the safer native behavior.

---

## 7. Preview Data

Create deterministic preview fixtures:

```text
Hourly rate: $23.00
Current period: Jul 4 – Jul 17, 2026
Entries:
- Jul 4: 6h 24m
- Jul 5: 7h 14m
- Jul 6: 5h 30m
- Jul 7: 8h 12m
- Jul 8: 6h 08m
```

Preview data must not be included as production user data.

---

## 8. Recommended First Implementation Order

1. Design tokens.
2. Shared buttons and cards.
3. Static Overview screen.
4. Entry editor and duration picker.
5. Work-entry persistence.
6. Entries screen.
7. Pay-period calculation integration.
8. History screen.
9. Settings.
10. Accessibility and visual polish.

Do not begin with animations, exports, backup, or optional settings.
