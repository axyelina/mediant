# Median't

Free, Tinder-style photo cleaner for iOS: swipe **left to delete**, **right to keep**. No ads,
no subscription, no payments — ever. SwiftUI, iOS 17+, iPhone only, portrait, dark-first.
Display name is **Median't**; everything code-facing (folders, targets, module, scheme) is
`Mediant` because the apostrophe breaks paths.

Design (the "project map"): `docs/superpowers/specs/2026-10-28-mediant-photo-cleaner-design.md`.
Mockups from the brainstorm: `docs/superpowers/mockups/` (open in a browser).

## Code map

| Folder | What lives there |
|---|---|
| `Mediant/Model/` | Pure logic, unit-tested: `visibleAssets` (album filter: no 👹, 💖 only with "Show 💖"), `DecisionStore` (kept/trashed per photo id, JSON in Application Support), `CleanupStats` (all-time deleted count + freed bytes, `stats.json`), `SwipeSession` (current index + undo stack), `ByteFormat` / `counted()` |
| `Mediant/Library/` | `PhotoLibrary` protocol + `PhotoKitLibrary`; `AlbumSizes` (background size sums); `ThumbnailLoader` (PHCachingImageManager) |
| `Mediant/App/` | `AppModel` (owns everything, reloads on library changes), `RootView`, `FloatingTabBar`, `AccessView` |
| `Mediant/Albums/`, `Album/` | Albums list (main page) with the `ProgressCard` (space freed / items deleted), and the album grid |
| `Mediant/Swipe/` | Swipe screen: `SwipeView` (page-slide drag), `PreviewStrip` (💖/👹 + ogre pop), `SparkleEdge`/`SparkleShape` (✨ edges), `PhotoPage` |
| `Mediant/Trash/` | `TrashModel` (one-batch delete, restore) and `TrashView` |
| `Mediant/Shared/` | `Chip` (the glass capsule button), `AssetImage` |
| `MediantTests/` | Swift Testing; `FakePhotoLibrary` stands in for PhotoKit |
| `Design/AppIcon/` | App icon sources: `light.svg` (✨ on the delete/keep diagonal split), `dark.svg`, `tinted.svg`. Edit the SVG, then `swift Design/AppIcon/render.swift` from the repo root writes the 1024 px PNGs into `AppIcon.appiconset` |

## Rules

- **PhotoKit stays behind `PhotoLibrary`.** Logic takes the protocol, so it is tested with
  `FakePhotoLibrary`. Only `PhotoKitLibrary` and `ThumbnailLoader` import Photos.
- **Deleting is only `TrashModel.emptyTrash()`** → one iOS dialog for the whole Trash. Never add an
  app-made confirmation on top, never delete per swipe.
- **Compact UI in thumb reach.** Controls are small glass `Chip`s, primary actions at the bottom.
- An image that fills its frame overflows it, and `.clipped()` does not stop the overflow from
  taking taps. `AssetImage` already turns off hit testing on the image; keep a
  `.contentShape(Rectangle())` on tappable cells.
- The preview strip has **no ScrollView**: `PreviewStrip.centers(around:in:)` calculates every tile
  position from the current photo and one animation moves them. A scroll view animating to a
  target while tiles resize made the strip jump — do not go back to `scrollPosition`.
- `project.yml` is the source of truth (XcodeGen). After adding/removing files run
  `xcodegen generate`. Never hand-edit the `.xcodeproj`.
- TDD for anything in `Model/`, `Library/` logic and view models.

## Simulator — HARD RULE

Use only the dedicated simulator **`Median't iPhone 16`** (iPhone 16, iOS 18.4) for building,
running and testing. Never target another simulator, even if one is already booted or attached.
It is kept in **dark appearance**. Use the `run-sim` skill (`.claude/skills/run-sim/`).

## Build, test, sample photos

```bash
.claude/skills/run-sim/scripts/run.sh          # build, install, launch on the dedicated sim
.claude/skills/run-sim/scripts/run.sh --test   # unit tests (replaces the running app!)
.claude/skills/run-sim/scripts/seed-photos.sh  # add 40 generated sample photos (once per sim)
```

Real iPhone (the user's phone `LINK`): `.claude/skills/run-device/scripts/run-device.sh` — see the
`run-device` skill. Signing uses the free personal team `WZHN8Q7J25`; the app expires after 7 days.

DerivedData goes to `./build/` (gitignored). `simctl privacy grant photos` does not work on
iOS 18.4 here: accept the app's permission dialog in the simulator instead.

## Git

No remote yet. The repo-local identity (`git config --local user.*`) is set by the user for this
repo; use it. If a remote is added, re-check the identity rule in the global instructions.

## Chat language

Write all chat replies in this project in **ASD-STE100 Simplified Technical English**: approved
words, one meaning per word, short sentences (procedures max 20 words, descriptions max 25),
active voice, one instruction per sentence, imperative for steps, vertical lists for sequences.
This rule applies to chat replies only, not to code, comments or docs, and only in this project.

## Maintenance

Keep this file and the project skills in `.claude/skills/` up to date as the project evolves:
when a workflow, convention or rule changes or is added, update them in the same change. When a
repeated multi-step workflow appears, capture it as a new skill.
