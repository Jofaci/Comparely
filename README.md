# Compare It — SwiftUI iOS App Draft

Local source only. This draft was built locally and was **not pushed to GitHub**.
Do not push until Josh explicitly gives the go, per his GitHub push rule.

## What it is

Compare two objects or ideas, add pros and cons for each, and review
them side by side. Saved comparisons live on the home screen so you can
return to them later.

## What is ready

- Home / saved comparisons list with search, swipe to delete, and
  per-item pro/con counts.
- Create comparison flow: optional title plus Item A and Item B names.
  After creation it moves straight into the editor.
- Pros and cons editor for each item, using the same editor for both
  sides: add, edit (tap an entry), flip pro to con and back, and delete.
- Final side-by-side view with a Stacked layout option for long entries,
  plus an editable verdict note.
- Local persistence with SwiftData only. No backend, no account, no paid
  API, no external dependency.

## What is mocked

- Nothing is mocked at runtime. Preview data in `PreviewData.swift`
  (Bike vs E-bike) exists only for SwiftUI previews.
- No sharing, export, sync, weighting, scoring, or AI suggestions.
  Counts are a simple tally only; the verdict is written by the user.

## How to open and build it later

This folder is a source draft, not a finished Xcode project bundle.
To run it:

1. On a Mac, open Xcode.
2. Create a new project: iOS App, interface SwiftUI, language Swift,
   name it `CompareIt`, minimum deployment iOS 17.
3. Replace the generated app files with the files in `CompareIt/`
   in this folder, keeping the folder structure:
   - `CompareItApp.swift` (the `@main` entry point)
   - `Models/` — `Comparison.swift`, `ComparedItem.swift`,
     `ProConEntry.swift`
   - `Views/` — `ComparisonListView.swift`, `CreateComparisonView.swift`,
     `ComparisonEditorView.swift`, `ItemProConEditorView.swift`,
     `ComparisonDetailView.swift`
   - `Components/` — `ProConRowView.swift`
   - `Theme.swift`, `PreviewData.swift`
4. Make sure the target uses SwiftData (iOS 17+) and that all files
   are members of the app target.
5. Build and run in the simulator or on an iPhone running iOS 17+.

No extra setup is needed. There are no packages to fetch, no keys,
and no backend to configure.

## Files

See `SPEC.md` for the spec, colour palette, data model, and open
questions for Josh.
