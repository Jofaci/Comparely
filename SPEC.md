# Compare It — Spec

## Short spec

A single-purpose iOS 17+ app for comparing exactly two things.

1. Home: a list of saved comparisons, most recently updated first,
   with search and swipe to delete.
2. Create: name an optional title and the two items (A and B).
3. Edit: add, edit, flip, and delete pros and cons for each item,
   switching between A and B with a segmented control.
4. Review: a final side-by-side view of both items' pros and cons,
   with an optional Stacked layout and a free-text verdict note.
5. Return: every saved comparison stays on the home screen for
   later review and editing.

Persistence is local only, via SwiftData. No backend, no account,
no paid API, and no external dependency.

## Fixes applied (2026-10-29, local structural edits only)

No Xcode / Swift toolchain is available in this environment, so
these edits are structural only. An Xcode build is still required
before shipping, and compilation is not claimed here.

1. **updatedAt touched only through store methods.** All mutations
   go through `Comparison` methods that call `touch()`:
   `renameItem`, `addEntry`, `toggleProCon`, `setEntryIsPro`,
   `saveEntry`, `deleteEntry`, and `saveVerdict`. Views never mutate
   `item.name`, `entry.text`, `entry.isPro`, `item.entries`, or
   `comparison.verdict` directly. The rename field, the entry edit
   sheet, and the verdict editor all work on local drafts committed
   through those methods. Opening Review or the editor without
   changing anything does not bump `updatedAt` (guards skip
   no-change commits). Deleting an entry still needs the view to
   call `modelContext.delete` after `deleteEntry` unlinks it, and
   adding an entry still needs the view to insert the returned
   entry into the context; the store method owns the link and the
   timestamp, not the context insert/delete itself.
2. **Explicit cascade delete rules and inverses.**
   `Comparison.items` is `@Relationship(deleteRule: .cascade,
   inverse: \ComparedItem.comparison)` and `ComparedItem.entries`
   is `@Relationship(deleteRule: .cascade, inverse:
   \ProConEntry.item)`. The child sides also declare their inverse
   explicitly (`ComparedItem.comparison` inverses `Comparison.items`,
   `ProConEntry.item` inverses `ComparedItem.entries`). Deleting a
   comparison deletes its items, and deleting an item deletes its
   entries, transitively.
3. **Side separated from sort order.** `ComparedItem.sortOrder` is
   renamed to `side` (0 = A, 1 = B). Side is identity, assigned
   once at creation in CreateComparisonView and never reassigned
   by any view or store method. Entry order inside an item is still
   `ProConEntry.sortOrder`, which is unrelated and unchanged.
   `itemA` returns the side 0 item, falling back to the first item
   in side order when no side 0 item exists; `itemB` returns the
   side 1 item when it is not already itemA, otherwise the first
   item in side order that is not itemA, or nil when fewer than
   two distinct items exist. A and B are therefore never the same
   item and a missing side never crashes. Note: renaming a stored
   SwiftData property is a schema change, so an existing local
   store built from the pre-fix draft may need a reinstall or a
   migration plan in Xcode; this is a draft-stage caveat, not a
   runtime migration.
4. **Blank name guards.** Names are trimmed everywhere. Create is
   disabled while either item name is blank or whitespace-only.
   `renameItem` returns false and changes nothing for a blank or
   whitespace-only name, and the editor reverts its rename draft
   to the stored name on rejection, so a saved item can never
   carry a blank name from create or rename.
5. **Tally labelled "Tally (unweighted)".** Each Review column
   header shows `Tally (unweighted): +2` / `-1` / `0` (pros minus
   cons, signed), alongside the pro/con counts. There is no
   automatic winner anywhere; the verdict note is the decision.
6. **Case-insensitive search, in memory only.** Home fetches with
   a static sort only (`updatedAt`, descending) and filters in
   memory with `Comparison.matchesSearch`, which folds case and
   diacritics and matches over `displayTitle` plus both item
   names. No predicate `contains` is run across the `items`
   relationship. Predicates are kept only for static filters.
7. **Retro-industrial styling (assumed answer, see below).**
   `Theme.swift` now uses sharp corners everywhere (corner radius
   0), a grooved divider (dark rule over light rule, via
   `GroovedDivider`), strong colour blocking, and an ink border on
   Review columns and the verdict field. Review column headers are
   full-width blocks in the item colour with the side letter and
   name in text. The A/B control in the editor is a custom
   sharp-cornered control (not a standard segmented Picker, which
   cannot tint segments individually): the selected half is filled
   with its item colour, the unselected half is flat panel grey,
   and each half is labelled "A" / "B" in text.

## Assumed answers (Josh did not answer; most likely for him)

- **Styling: go retro-industrial.** Strict minimalist 1980s
  retro-industrial, sharp geometry, colour-blocked utility, and
  Eurostile-style type as far as SwiftUI allows, matching Josh's
  taste. Eurostile itself is not bundled with iOS, so display text
  uses bold system sans, uppercased, with wide tracking; no custom
  Eurostile font is claimed or shipped.
- **A/B coding kept, never colour alone.** Teal for A and burnt
  orange for B are kept, and every colour block is paired with a
  text label: "A" / "B" on headers and the A/B control, plus/minus
  icons and Pro/Con labels on rows and section headers.
- **Distinct from Money Manager.** Money Manager's calm deep teal
  plus warm paper is not copied: Compare It uses harder colour
  blocking, square corners, grooved dividers, and ink borders, on
  the same paper/teal/orange base so A/B coding stays clear.

## Deliberately NOT added

- No weighted scoring and no automatic winner (tally only).
- No 3-way comparisons: exactly two items, A and B.
- No sharing or export, no accounts, no backend sync.

## Colour palette chosen and why

| Role | Colour | Why |
| --- | --- | --- |
| Paper background | Warm off-white `#F6F6F3` | Softer than pure white for long lists, keeps a paper / notebook feel. |
| Surface | White `#FFFFFF` | Cards stand out from the background, with a hard ink border. |
| Ink | Near-black `#16181D` | Main text, strong contrast on paper and white; also the card border. |
| Muted | Grey `#6B7280` | Secondary text and counts, clearly below ink in hierarchy. |
| Item A | Teal `#0F766E` | Colour-blocked side A, distinct from side B. |
| Item B | Burnt orange `#C2410C` | Colour-blocked side B, distinct from side A. |
| Pro | Green `#15803D` | Conventional pro signal, paired with a plus icon and the word Pro. |
| Con | Red `#B91C1C` | Conventional con signal, paired with a minus icon and the word Con. |
| Panel (unselected A/B) | Grey `#E5E5E0` | Flat unselected half of the A/B control. |
| Groove dark / light | `#9E9E99` / white | Machined grooved divider between Review sections. |

Pros and cons never rely on colour alone: each row also has a
plus/minus icon and a Pro/Con label in section headers, and each
side also has its "A" / "B" letter in text, which keeps the view
usable for colour-blind users.

## Core screens and flows

- **ComparisonListView (Home):** saved comparisons, search,
  delete, tap to open the side-by-side review.
- **CreateComparisonView:** title (optional), Item A name,
  Item B name. Both item names are required and trimmed; blank or
  whitespace-only names cannot save. On Create, the app saves the
  comparison and moves into the editor.
- **ComparisonEditorView:** container with a custom A/B control
  (selected half filled with that item's colour, labelled A / B)
  and a Review button.
- **ItemProConEditorView:** the per-item editor, reused for A
  and B. Rename the item (draft committed via `renameItem`, blank
  renames rejected and reverted), add a pro or con, tap to edit,
  swipe to delete or flip pro/con, all via `Comparison` store
  methods.
- **ComparisonDetailView (Final view):** side-by-side columns
  by default, Stacked toggle for long text, per-item counts and
  a "Tally (unweighted)" line, colour-blocked column headers,
  grooved dividers, and an editable verdict note committed via
  `saveVerdict`. Edit button returns to the editor.

Flow: Home → Create → Editor (A, then B) → Review → Home.
From Review, Edit returns to the editor; from Home, tapping a
saved comparison returns straight to Review.

## Data model (SwiftData)

- **Comparison**
  - `id: UUID`, `title: String`, `verdict: String`
  - `createdAt: Date`, `updatedAt: Date`
  - `items: [ComparedItem]` (cascade delete, inverse
    `ComparedItem.comparison`)
  - Computed: `sortedItems` (by `side`), `itemA`, `itemB` (with
    safe fallbacks above, never the same item), `displayTitle`
    (falls back to "A vs B" when the title is blank),
    `totalPros`, `totalCons`, `matchesSearch`
  - Store methods only (all call `touch()`): `renameItem`,
    `addEntry`, `toggleProCon`, `setEntryIsPro`, `saveEntry`,
    `deleteEntry`, `saveVerdict`
- **ComparedItem**
  - `id: UUID`, `name: String`, `side: Int` (0 = A, 1 = B,
    assigned once at creation, never changed)
  - `comparison: Comparison?` (inverse of `Comparison.items`)
  - `entries: [ProConEntry]` (cascade delete, inverse
    `ProConEntry.item`)
  - Computed: `pros`, `cons`, `score` (pros minus cons, tally
    only, shown as "Tally (unweighted)"), `signedScore`,
    `sideLabel` ("A" / "B")
- **ProConEntry**
  - `id: UUID`, `text: String`, `isPro: Bool`, `sortOrder: Int`
    (order within its item only, unrelated to `side`)
  - `item: ComparedItem?` (inverse of `ComparedItem.entries`)

Deleting a comparison deletes its items and entries. Deleting an
item's entry updates the parent comparison's `updatedAt` via
`deleteEntry`. Every other mutation likewise goes through a store
method that touches `updatedAt`.

## Open questions for Josh

These are defaults that work now and would only change the build
if Josh answers differently. Nothing here blocks running the draft.
The styling question is now answered by assumption (retro-
industrial, above) and is kept here only as a record of what was
assumed; Josh can still override it.

1. **Colours and style:** assumed retro-industrial (sharp corners,
   grooved dividers, Eurostile-style type, stronger colour
   blocking) to match his design taste. Confirm or override?
2. **More than two items:** is two items always enough, or should
   a comparison ever allow three or more sides? (Not built.)
3. **Weighting or scoring:** keep counts as a plain "Tally
   (unweighted)" with a handwritten verdict, or add weighted
   pros/cons and an automatic winner suggestion? (Not built.)
4. **Sharing and export:** add share as text, image, or PDF of the
   side-by-side view, or keep it private and local only? (Not built.)
5. **Sorting and grouping:** is recency order plus search enough,
   or should saved comparisons support folders, favourites, or tags?
6. **Entry extras:** should a pro or con support a note, a photo,
   or a link, or stay as one short line of text?
