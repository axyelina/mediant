# Trash Viewer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tap a Trash tile to see the photo or video full screen, browse the Trash left / right, and restore one item.

**Architecture:** Model logic (library lookup by id, single restore, the index after a restore) is pure and unit-tested. A new `TrashViewer` screen, shown with `fullScreenCover` from `TrashView`, reuses `PhotoPage`, `LoopingVideo`, `VideoChip` and `SwipeGesture` (next / previous / back).

**Tech Stack:** SwiftUI, iOS 17+, PhotoKit behind `PhotoLibrary`, Swift Testing, XcodeGen.

**Spec:** `docs/superpowers/specs/2026-11-20-trash-viewer-design.md`

## Global Constraints

- Only `PhotoKitLibrary` / `ThumbnailLoader` import Photos; logic takes `PhotoLibrary`, tested with `FakePhotoLibrary`.
- Deleting stays only `TrashModel.emptyTrash()`; the viewer never deletes and adds no confirmation.
- Every UI text in `Localizable.xcstrings` with Russian; new key `Restore` → `Восстановить`.
- After adding files: `xcodegen generate` (the run script does it when `project.yml` is newer; new files need it explicitly).
- Build / test only on `Median't iPhone 16`: `.claude/skills/run-sim/scripts/run.sh [--test]`.
- Commits as `axyelina <axyelina@gmail.com>` (repo-local), ending with the Co-Authored-By line.

## Review Focus

- The viewed item leaves the Trash from elsewhere (library change forgets it): the viewer must not crash on a stale index; it shows a neighbor or closes.
- A trashed id that is no longer in the library (`assets(withIDs:)` leaves it out): viewer index math uses the found assets, not raw ids.
- Restore of the last item in the list shows the previous one; restore of the only item closes.
- A video playing in the viewer stops when the viewer closes or the item changes (one `VideoPlayback` owned by the viewer).
- Select mode: a tap still toggles selection and never opens the viewer.

---

### Task 1: Model — lookup by id, single restore, index after restore

**Files:**
- Modify: `Mediant/Library/PhotoLibrary.swift` (protocol), `Mediant/Library/PhotoKitLibrary.swift`, `MediantTests/FakePhotoLibrary.swift`
- Modify: `Mediant/Trash/TrashModel.swift`
- Create: `Mediant/Model/TrashBrowse.swift`
- Test: `MediantTests/TrashModelTests.swift`, create `MediantTests/TrashBrowseTests.swift`

**Interfaces:**
- Produces: `PhotoLibrary.assets(withIDs ids: [String]) -> [AssetInfo]` (input order, unknown ids left out); `TrashModel.restore(_ id: String)`; `enum TrashBrowse { static func index(afterRestoring index: Int, count: Int) -> Int? }` where `count` is the count before the restore.

- [ ] **Step 1: Failing tests**
  - `TrashBrowseTests`: `index(afterRestoring: 1, count: 3) == 1`; `index(afterRestoring: 2, count: 3) == 1`; `index(afterRestoring: 0, count: 1) == nil`.
  - `TrashModelTests.restoreOneTakesOnlyThatItem`: trash `a`, `b`; `trash.restore("a")` → `store.trashedIDs == ["b"]`, `store.decision(for: "a") == nil`.
  - `TrashModelTests` (or a library test using the fake): `assets(withIDs: ["b", "x", "a"])` on a fake whose album holds `a`, `b` → ids `["b", "a"]`.
- [ ] **Step 2:** `run.sh --test` → fails to compile (missing members).
- [ ] **Step 3: Implement.** PhotoKit: `PHAsset.fetchAssets(withLocalIdentifiers:options:)`, build `AssetInfo` as `assets(inAlbum:)` does (share a private helper), then reorder to the input order. Fake: search `assetsByAlbum.values`. `TrashModel.restore(_:)` calls `store.restore([id])`.
- [ ] **Step 4:** `run.sh --test` → "Tests passed".
- [ ] **Step 5:** `xcodegen generate`, commit `feat: Trash lookup by id and single restore`.

### Task 2: TrashViewer screen and the Trash grid hookup

**Files:**
- Create: `Mediant/Trash/TrashViewer.swift`
- Modify: `Mediant/Trash/TrashView.swift`, `Mediant/Localizable.xcstrings`, `CLAUDE.md` (code map: `Trash/`), `docs/superpowers/specs/2026-10-28-mediant-photo-cleaner-design.md` (Trash section)

**Interfaces:**
- Consumes: Task 1; `PhotoPage(asset:plays:)`, `VideoChip(asset:)`, `VideoPlayback` (environment), `SwipeGesture.outcome(startX:translation:predictedEnd:)`, `Chip`, `GlassGroup`, `ByteFormat.string(_:locale:)`.
- Produces: `TrashViewer(startID: String)`; `TrashView` presents it with `fullScreenCover(item:)` on a tapped id.

- [ ] **Step 1: Viewer.** Items = `model.library.assets(withIDs: store.trashedIDs.reversed())` (grid order), recomputed when `trashedIDs` changes; current id kept in state, index found by id (fallback: `TrashBrowse` neighbor, or dismiss when empty). Carousel and edge-back like `SwipeView` (`.next` / `.previous` / `.back`; `.trash` / `.keep` spring back). Top: `Chip("‹ Back")`. Bottom row: size label (+ `VideoChip` and mute chip for videos), `Spacer`, `Chip("Restore")` → `trash.restore(id)`, light impact haptic, move to `TrashBrowse.index(afterRestoring:count:)` or dismiss. Own `@State VideoPlayback`, `.environment(\.colorScheme, .dark)`, black background.
- [ ] **Step 2: Grid.** `TrashView.tile`: tap outside Select mode sets the presented id; add the album grid's `▶ 0:20` video mark (needs `AssetInfo` for tiles: look up once per `ids` change with `assets(withIDs:)`).
- [ ] **Step 3: Strings and docs.** Add `Restore` / `Восстановить`; update `CLAUDE.md` code map and the design doc's Trash section.
- [ ] **Step 4: Verify on the sim.** `run.sh`; trash a photo and a video on the swipe screen; in the Trash: tap opens, left / right browse, video plays with chips, edge swipe and Back close, Restore moves to the next item and the 👹 count drops, restoring the last item closes the viewer; Select mode tap only selects. `run.sh --test` still passes.
- [ ] **Step 5:** Commit `feat: full-screen Trash viewer with single restore`.
