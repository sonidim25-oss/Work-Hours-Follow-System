# Work Hours Follow — Design System

## 1. Status

This document is the visual source of truth for the iOS implementation.

The design reference is located at:

```text
Design/References/Design_Board.png
```

Individual screen crops are located in the same folder.

The implementation should reproduce this design as closely as practical while preserving native iOS behavior, accessibility, Dynamic Type, and safe-area requirements.

---

## 2. Design Direction

The visual identity combines:

- deep navy backgrounds;
- warm cream content cards;
- restrained muted-gold accents;
- a red primary action color;
- serif display typography;
- compact native iOS controls;
- a calm personal-ledger atmosphere.

The interface should feel like a premium private work journal rather than a modern analytics dashboard.

Avoid:

- glassmorphism;
- bright gradients;
- excessive animation;
- large colorful charts;
- heavy shadows;
- crowded layouts;
- generic SaaS styling.

---

## 3. Color Tokens

Use semantic tokens rather than direct colors inside views.

```swift
enum AppColor {
    static let background = Color(hex: "#061321")
    static let backgroundElevated = Color(hex: "#0E1B2E")
    static let surfaceDark = Color(hex: "#16273F")
    static let surfaceCream = Color(hex: "#F4EDE1")
    static let textPrimaryLight = Color(hex: "#F4EDE1")
    static let textPrimaryDark = Color(hex: "#142033")
    static let textSecondary = Color(hex: "#8D94A1")
    static let gold = Color(hex: "#C9A66B")
    static let accent = Color(hex: "#D8332A")
    static let success = Color(hex: "#3E7D5A")
    static let divider = Color.white.opacity(0.10)
}
```

### Color usage

| Token | Usage |
|---|---|
| `background` | Main application background |
| `backgroundElevated` | Tab bar, grouped sections, editor panels |
| `surfaceDark` | Dark cards and input containers |
| `surfaceCream` | Work-entry cards, history cards, summary cards |
| `textPrimaryLight` | Primary text on dark backgrounds |
| `textPrimaryDark` | Primary text on cream cards |
| `textSecondary` | Supporting labels and metadata |
| `gold` | Earnings, icons, secondary emphasis |
| `accent` | Main action, active tab, destructive emphasis |
| `success` | Paid status |
| `divider` | Subtle borders and separators |

Do not introduce new colors without updating this file.

---

## 4. Typography

### Font families

Use:

- **New York** or **Playfair Display** for display and section headings.
- **SF Pro** for body text, controls, values, and navigation.

Prefer Apple's built-in New York font when possible to avoid bundling external font files.

### Text styles

| Style | Font | Size | Weight | Usage |
|---|---|---:|---|---|
| App title | New York | 34 | Semibold | Main screen title |
| Screen title | New York | 30 | Semibold | History, Settings, Entries |
| Section title | New York | 22 | Medium | Card and section titles |
| Large metric | New York | 38 | Semibold | Total hours and earnings |
| Picker value | New York | 36 | Medium | Selected hours and minutes |
| Headline | SF Pro | 17 | Semibold | Row and field labels |
| Body | SF Pro | 16 | Regular | General content |
| Callout | SF Pro | 15 | Medium | Dates and durations |
| Caption | SF Pro | 13 | Regular | Supporting metadata |
| Small caption | SF Pro | 11 | Medium | Tab labels and badges |

Use tabular numbers for durations and currency where available.

---

## 5. Spacing Tokens

Use an 4-point spacing grid.

```swift
enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
}
```

Primary layout rules:

- horizontal screen padding: `24`;
- card internal padding: `16`;
- vertical spacing between cards: `12`;
- spacing between major sections: `24–32`;
- bottom content clearance above tab bar: at least `24`.

---

## 6. Corner Radius

```swift
enum AppRadius {
    static let small: CGFloat = 10
    static let medium: CGFloat = 14
    static let card: CGFloat = 16
    static let large: CGFloat = 22
}
```

Usage:

- list and settings rows: `10–14`;
- standard cards: `16`;
- primary buttons: `12–14`;
- sheets and large containers: `22`.

Do not use pill shapes except for compact badges.

---

## 7. Borders and Shadows

Use borders more often than shadows.

Dark cards:

```swift
.overlay(
    RoundedRectangle(cornerRadius: AppRadius.card)
        .stroke(Color.white.opacity(0.10), lineWidth: 1)
)
```

Cream cards may use a minimal shadow:

```swift
.shadow(color: .black.opacity(0.10), radius: 8, y: 3)
```

Avoid dramatic floating-card effects.

---

## 8. Icons

Use SF Symbols.

Recommended mapping:

| Action | Symbol |
|---|---|
| Overview | `house.fill` |
| Entries | `list.bullet.rectangle` |
| History | `clock.arrow.circlepath` |
| Settings | `gearshape.fill` |
| Add | `plus` |
| Edit | `pencil` |
| Delete | `trash` |
| Calendar | `calendar` |
| Duration | `clock` |
| Earnings | `dollarsign` |
| Export | `square.and.arrow.up` |
| Backup | `icloud.and.arrow.up` |
| Info | `info.circle` |
| Help | `questionmark.circle` |
| Disclosure | `chevron.right` |

Use `gold` for secondary icons and `accent` for selected navigation or destructive actions.

---

## 9. Navigation

Use a persistent four-tab bottom bar:

1. Overview
2. Entries
3. History
4. Settings

The active tab uses the red accent color. Inactive tabs use muted gray.

The tab bar should use the dark elevated surface and a subtle top border.

---

## 10. Motion

Animations should be short and functional.

Allowed:

- 0.15–0.25 second state transitions;
- card insertion and removal;
- number updates;
- sheet presentation;
- selection feedback.

Avoid:

- bouncing elements;
- decorative parallax;
- looping animation;
- long transitions.

Respect Reduce Motion.

---

## 11. Accessibility

- Support Dynamic Type.
- Preserve at least 44×44 point interactive areas.
- Do not encode status using color alone.
- Add VoiceOver labels for icon-only controls.
- Keep text contrast compliant.
- Let large text wrap rather than clip.
- Use native sheets, alerts, and navigation where practical.

Pixel accuracy must not override accessibility.
