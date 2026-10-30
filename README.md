<p align="center">
  <img src="Mediant/Assets.xcassets/AppIcon.appiconset/AppIcon-dark.png" width="128" alt="Median't app icon">
</p>

<h1 align="center">Median't</h1>

<p align="center">
  A free, Tinder-style photo cleaner for iPhone.<br>
  Swipe <b>left to delete</b>, <b>right to keep</b>.
</p>

---

You have paid for apps like this before. Median't is the one you don't pay for: **no ads, no
subscription, no in-app purchases, no tracking — ever.** Your photos never leave your phone.

## Features

- **Albums first.** Every non-empty album with its item count and storage size. Recents comes
  first, then Favorites, Recently Added, Videos, Screenshots and Selfies, then the rest A–Z.
- **Swipe to decide.** Open any photo in an album and go to older ones: left marks it 👹 for the
  Trash, right keeps it 💖, a tap skips it. Undo is always one tap away.
- **See what you free.** Every photo shows its size; every album shows its total.
- **Video too.** Videos loop on the card; tap the time chip to pause, drag it to scrub, 🔊/🔇 to
  mute.
- **Safe deleting.** A swipe only marks a photo. Real deletion happens once, for the whole Trash,
  through a single iOS dialog — and iOS still keeps the photos in "Recently Deleted" for 30 days.
- **Progress.** All-time "space freed" and "items deleted" on the main page.
- **Trash reminder.** One quiet notification if you leave a full Trash behind (can be turned
  off).
- **English and Russian**, switchable in Settings.
- Compact glass controls at the bottom, in thumb reach. Dark-first.

## Requirements

- iPhone with iOS 17 or later (portrait only).
- To build: Xcode 16+, [XcodeGen](https://github.com/yonaskolb/XcodeGen)
  (`brew install xcodegen`). No third-party dependencies.

## Build and run

`project.yml` is the source of truth; the `.xcodeproj` is generated from it.

```bash
xcodegen generate                              # after adding or removing files
open Mediant.xcodeproj                         # build and run the Mediant scheme
```

Or use the helper scripts, which build and launch on a dedicated `Median't iPhone 16`
simulator (iOS 18.4) and create it if needed:

```bash
.claude/skills/run-sim/scripts/run.sh          # build, install, launch
.claude/skills/run-sim/scripts/run.sh --test   # run the unit tests
.claude/skills/run-sim/scripts/seed-photos.sh  # add 40 sample photos + 4 videos (once)
```

On first launch, allow access to Photos in the app's own dialog.

To run on a real iPhone, set your own team in `project.yml` (`DEVELOPMENT_TEAM`) or in Xcode's
Signing settings. Apps signed with a free personal team expire after 7 days.

## How it is built

SwiftUI and PhotoKit, nothing else.

- `Mediant/Model/` — pure, unit-tested logic: decisions, swipe session and undo, album order and
  filter, stats, Trash reminder timing.
- `Mediant/Library/` — PhotoKit stays behind the `PhotoLibrary` protocol, so logic is tested
  with a fake library.
- `Mediant/Swipe/`, `Albums/`, `Album/`, `Trash/`, `Settings/` — the screens.
- `MediantTests/` — Swift Testing.
- `Design/AppIcon/` — icon and launch art as SVG; `swift Design/AppIcon/render.swift` renders
  the PNGs.

A detailed code map and the project rules are in [`CLAUDE.md`](CLAUDE.md).

## Docs

- Design: [`docs/superpowers/specs/2026-10-28-mediant-photo-cleaner-design.md`](docs/superpowers/specs/2026-10-28-mediant-photo-cleaner-design.md)
- Mockups: [`docs/superpowers/mockups/`](docs/superpowers/mockups/) (open in a browser)
- Ideas and what has shipped: [`TODO.md`](TODO.md)
