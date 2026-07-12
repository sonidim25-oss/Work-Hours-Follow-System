# Functional Vertical Slice Verification

**Date:** July 12, 2026  
**Result:** Passed  
**Xcode:** 26.6 (17F113)  
**Simulator runtime:** iOS 26.5 (23F77)

## Devices

- iPhone 17 Pro, `E6B7FFEA-E21B-4233-802C-3CF438D9059A`, 402 × 874 points.
- iPhone SE (3rd generation), `BEE9D40E-FFFA-4E0B-9046-E580E5699695`, 375 × 667 points. This was a disposable Task 9 simulator.

The calendar used the live Toronto date of July 12, 2026. The active period was July 3–16, the next payday was July 17, and July 13 was the first future date exercised in the editor.

## Automated verification

The unit target was first run alone to establish its exact count:

```sh
xcodebuild test -project WorkHoursFollow.xcodeproj -scheme WorkHoursFollow \
  -destination 'platform=iOS Simulator,id=E6B7FFEA-E21B-4233-802C-3CF438D9059A' \
  -derivedDataPath .build/DerivedData -parallel-testing-enabled NO \
  -only-testing:WorkHoursFollowTests
```

Result: `47 tests, with 0 failures` and `** TEST SUCCEEDED **`.

The complete, nonparallel scheme was then run on iPhone 17 Pro:

```sh
xcodebuild test -project WorkHoursFollow.xcodeproj -scheme WorkHoursFollow \
  -destination 'platform=iOS Simulator,id=E6B7FFEA-E21B-4233-802C-3CF438D9059A' \
  -derivedDataPath .build/DerivedData -parallel-testing-enabled NO
```

Result: `** TEST SUCCEEDED **`. The scheme contains 47 unit tests and four focused XCUITests. The unit tests cover duration, earnings rounding, pay-period boundaries (including July 16/17), validation, persistence rollback, rate snapshots, formatting, and period summaries. The UI tests cover the live period, empty and populated screens, add/edit/delete/duplicate behavior, persistence after process relaunch, deterministic launch isolation, the small-screen layout, and accessibility Dynamic Type.

Every XCUITest begins with the exact `--ui-testing-reset-data` launch argument. In `DEBUG` builds only, the app deletes `WorkEntry` and `AppSettings` records, saves fresh documented defaults, and exposes `ui-test-reset-complete` after the reset finishes. The persistence assertion explicitly removes the argument before relaunching, so it verifies durable state rather than resetting it. A separate UI test seeds an entry and proves a later reset launch returns totals to zero.

The default and Accessibility Extra Extra Extra Large iPhone SE checks are exactly reproducible with:

```sh
xcrun simctl ui BEE9D40E-FFFA-4E0B-9046-E580E5699695 content_size large
xcodebuild test -project WorkHoursFollow.xcodeproj -scheme WorkHoursFollow \
  -destination 'platform=iOS Simulator,id=BEE9D40E-FFFA-4E0B-9046-E580E5699695' \
  -derivedDataPath .build/DerivedDataSE -parallel-testing-enabled NO \
  -only-testing:WorkHoursFollowUITests/FunctionalVerticalSliceUITests/testOverviewShowsExpectedLivePeriod

xcrun simctl ui BEE9D40E-FFFA-4E0B-9046-E580E5699695 \
  content_size accessibility-extra-extra-extra-large
xcodebuild test -project WorkHoursFollow.xcodeproj -scheme WorkHoursFollow \
  -destination 'platform=iOS Simulator,id=BEE9D40E-FFFA-4E0B-9046-E580E5699695' \
  -derivedDataPath .build/DerivedDataSE -parallel-testing-enabled NO \
  -only-testing:WorkHoursFollowUITests/FunctionalVerticalSliceUITests/testAccessibilityDynamicTypeLayoutRemainsNavigable
xcrun simctl ui BEE9D40E-FFFA-4E0B-9046-E580E5699695 content_size large
```

Both focused runs reported zero failures.

The generic simulator build was also run independently:

```sh
xcodebuild build -project WorkHoursFollow.xcodeproj -scheme WorkHoursFollow \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO
```

Result: `** BUILD SUCCEEDED **`.

The resulting app bundle was independently installed and launched with `simctl`; process identifier `48433` was returned. The retained screenshot is the settled first interactive frame, including the **Safe Defaults Restored** alert and enabled **OK** action, rather than a launch placeholder. The retained runtime file is a 0.711-second launch trace (15:29:33.146–15:29:33.857) selected by a five-minute query window. It contains normal UIKit and simulator lifecycle messages, with no app crash, SwiftData failure, or uncaught error.

## Simulator acceptance flow

The repeatable `testAddEditDuplicateDeleteAndRelaunchPersistence` flow verified:

1. Empty Overview showed `0h 0m`, `$0.00`, July 3–16, and payday July 17.
2. July 13 was disabled in the date picker on July 12, and Save was disabled for zero duration.
3. July 10 at 10h 12m previewed and saved `$234.60`.
4. July 8 at 1h 30m updated totals to `11h 42m` and `$269.10`.
5. A second July 10 save presented **Entry Already Exists** with **Edit Existing Entry** and **Cancel**.
6. Choosing **Edit Existing Entry** restored the persisted 10h 12m duration. Editing it to 9h 0m updated totals to `10h 30m` and `$241.50`.
7. The July 10 delete dialog was first dismissed by tapping outside the native iOS 26 confirmation dialog; the row remained. A second attempt confirmed deletion and removed the row.
8. The app process was terminated and relaunched. July 8 remained and July 10 remained deleted, proving durable SwiftData persistence.
9. Test-created data was removed after the retained relaunch screenshot so the UI test is repeatable.

## Visual and accessibility review

The Overview, Entries, and editor were compared against `Design_Board.png`, `02_Entries.png`, and `03_Add_Edit_Entry.png`. The implementation preserves the deep navy background, cream ledger cards, gold emphasis, red primary action, serif display metrics, standard tab navigation, 24-point screen padding, 16-point card padding, and rounded card proportions. The graphical date picker intentionally follows native iOS behavior instead of copying the static mockup literally.

- Default layouts passed on both Pro and SE-sized screens without clipping.
- Accessibility Extra Extra Extra Large passed on iPhone SE. The Overview remained scrollable, the wrapped Add action was fully visible at least 8 points above the tab bar, and the editor retained both picker wheels and its validation text. The editor title moves below the action row at accessibility sizes, preventing toolbar crowding.
- Interactive cards and primary actions expose descriptive labels. Decorative plus/chevron images are hidden from accessibility where their surrounding control supplies the label. Native tab items expose labels for all four icons.
- UI geometry assertions require Cancel to be hittable, both editor actions to be at least 44 points wide and high, 8-point window-edge insets, and no action/title intersection. They passed at default and Accessibility Extra Extra Extra Large sizes on iPhone SE. Date cells are native 44-point controls; entry cards and primary actions exceed 44 points in both dimensions.
- Validation and destructive states include text, labels, and system roles rather than relying on color alone.
- The app defines no custom animation, transition, or motion-only information; Reduce Motion therefore leaves application behavior unchanged and native system transitions remain system-controlled.
- The editor uses wheel pickers rather than text fields, so there is no software keyboard obscuring duration input. Its scroll view keeps the picker and earnings sections reachable on both devices and at accessibility sizes.
- Accessibility hierarchy inspection confirmed labels and values. The XCUITest runner emitted an iOS 26.5 duplicate WebKit accessibility-bundle diagnostic; this is a simulator runtime warning and did not affect assertions.

## Corrected defect

Initial UI automation found the app using a legacy 320 × 480 compatibility canvas on iPhone 17 Pro. This placed the Overview action below the visible viewport. The generated Info.plist lacked a launch-screen declaration. Enabling Xcode’s generated launch screen for Debug and Release restored the native 402 × 874 canvas. The previously failing `isHittable` regression assertion then passed on Pro and SE.

Review also found that the native navigation toolbar compressed Cancel below 44 points and crowded the title on the SE and at accessibility sizes. The editor now uses an adaptive header with explicit 64 × 44-point minimum action frames; the title stays inline at standard sizes and moves to its own row for accessibility sizes. The focused geometry assertions and recaptured screenshots cover both variants.

## Evidence

Screenshots and the runtime log are in [`docs/verification/evidence`](evidence):

- `01-overview-empty-pro.png` and `01-overview-empty-se.png`
- `02-editor-default-pro.png` and `02-editor-default-se.png`
- `03-add-july-10-pro.png`
- `04-overview-populated-pro.png`
- `05-duplicate-alert-pro.png`
- `06-entries-pro.png`
- `07-persistence-relaunch-pro.png`
- `08-overview-axxxl-se.png`
- `09-editor-axxxl-se.png`
- `10-independent-install-launch-pro.png`
- `runtime-log.txt`

## Remaining scope

History and Settings remain clearly non-interactive milestone placeholders. Their functionality is intentionally not marked complete in `docs/TODO.md`.
