# Median't Photo Cleaner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the swipe-to-clean photo app described in the spec: albums list → album grid → swipe screen, plus a Trash tab that deletes in one batch.

**Architecture:** SwiftUI + `@Observable` (iOS 17). PhotoKit sits behind a `PhotoLibrary` protocol so the decision/session/size logic is unit-tested with a fake. Decisions (kept/trashed) live in a JSON-persisted `DecisionStore`; a `SwipeSession` drives one swipe run with an undo stack. Views are thin.

**Tech Stack:** Swift 5 mode, SwiftUI, Observation, PhotoKit, Swift Testing, XcodeGen.

**Spec:** `docs/superpowers/specs/2026-10-28-mediant-photo-cleaner-design.md` (mockups in `docs/superpowers/mockups/`).

## Global Constraints

- iOS 17.0+, iPhone only, portrait. No third-party dependencies. No ads, analytics, IAP.
- Build/test only on the simulator `Median't iPhone 16` via `.claude/skills/run-sim/scripts/run.sh [--test]`.
- After adding files run `xcodegen generate` (the script does it when `project.yml` is newer; new files under existing source folders need a regenerate too — run it explicitly).
- Real deletion only through `PhotoLibrary.delete(_:)` from the Trash "Empty" action. No app-made confirmation dialog.
- Emoji: kept = 💖, trashed = 👹. Undo chip text "↶ Undo". Back chip "‹ Back".
- Commit identity: repo-local (already set). Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

- Asset deleted outside the app (or in iCloud) while it is in the Trash / store → dropped on next load, Trash count correct, no crash (Task 1 `removeMissing`).
- Undo at the first photo / with empty history → no-op; undo after "All done" → returns to the last photo (Task 2).
- User taps "Don't Allow" in the iOS delete dialog → Trash unchanged (Task 6, `emptyTrash` keeps ids when `delete` throws).
- Limited or denied Photos access → explanation screen, no empty-forever spinner (Task 3/4).
- Album with 0 items or asset with no size info → album hidden / size shows "—", sums ignore missing (Task 3 tests).

---

### Task 1: Decisions, persistence, byte formatting

**Files:**
- Create: `Mediant/Model/Decision.swift`, `Mediant/Model/DecisionStore.swift`, `Mediant/Model/ByteFormat.swift`
- Test: `MediantTests/DecisionStoreTests.swift`, `MediantTests/ByteFormatTests.swift`
- Delete: `MediantTests/MediantTests.swift` (placeholder)

**Interfaces — Produces:**
- `enum Decision: String, Codable { case kept, trashed }`
- `@MainActor @Observable final class DecisionStore` — `init(fileURL: URL)`; `func decision(for id: String) -> Decision?`; `func set(_ decision: Decision?, for id: String)`; `private(set) var trashedIDs: [String]` (insertion order, newest last); `var trashCount: Int`; `func restore(_ ids: [String])` (→ undecided); `func removeMissing(keeping existing: Set<String>)`; `func clearTrash(_ ids: [String])` (forget those ids entirely). Saves JSON on every mutation; loads in `init` (missing/corrupt file → empty).
- `enum ByteFormat { static func string(_ bytes: Int64?) -> String }` — decimal file style ("4.2 MB"), `nil` → "—". Normalize non-breaking spaces to plain spaces.

- [ ] **Step 1: Failing tests** — `setAndReadBack` (trash "a", keep "b" → decisions match, `trashedIDs == ["a"]`), `persistsAcrossInstances` (new store on same URL sees same state), `retrashKeepsSingleEntry`, `restoreMakesUndecided`, `removeMissingDropsUnknownIDs` (trash a,b; keep c; `removeMissing(keeping: ["a"])` → trashedIDs ["a"], c undecided), `corruptFileStartsEmpty`; `ByteFormat.string(4_200_000) == "4.2 MB"`, `string(nil) == "—"`, `string(0) == "Zero KB"` (accept whatever `ByteCountFormatter` gives for 0 — assert it is non-empty).
- [ ] **Step 2:** `run.sh --test` → fails to compile.
- [ ] **Step 3:** Implement. Store state as `[String: Decision]` + ordered trash array in one `Codable` struct.
- [ ] **Step 4:** `run.sh --test` → all pass.
- [ ] **Step 5:** Commit `feat: decision store and byte formatting`.

### Task 2: Swipe session

**Files:** Create `Mediant/Model/SwipeSession.swift`; Test `MediantTests/SwipeSessionTests.swift`

**Interfaces — Consumes:** `DecisionStore`. **Produces:**
- `@MainActor @Observable final class SwipeSession` — `init(assetIDs: [String], startIndex: Int, store: DecisionStore)`; `private(set) var index: Int`; `var currentID: String?` (nil when finished); `var isFinished: Bool`; `var canUndo: Bool`; `func commit(_ decision: Decision)` (store.set, push `(index, id, previous)` on history, index += 1); `func undo()` (pop, restore previous decision, index = that index); `func jump(to index: Int)` (clamped; does not touch history).

- [ ] **Step 1: Failing tests** — `startsAtGivenIndex`, `commitAdvancesAndRecords` (trash at 0 → index 1, store says trashed), `undoRestoresPreviousDecision` (keep x, then later trash x via jump+commit, undo → kept again, index back), `undoWithEmptyHistoryIsNoop`, `finishesAfterLast` (2 ids, commit twice → isFinished, currentID nil), `undoAfterFinishReturnsToLast`, `jumpClamps`.
- [ ] **Step 2–4:** red → implement → green (`run.sh --test`).
- [ ] **Step 5:** Commit `feat: swipe session with undo`.

### Task 3: PhotoLibrary protocol, PhotoKit implementation, album sizes

**Files:**
- Create: `Mediant/Library/PhotoLibrary.swift` (protocol + value types), `Mediant/Library/PhotoKitLibrary.swift`, `Mediant/Library/AlbumSizes.swift`, `Mediant/Library/ThumbnailLoader.swift`
- Test: `MediantTests/AlbumSizesTests.swift`, `MediantTests/FakePhotoLibrary.swift`
- Modify: `project.yml` — add `INFOPLIST_KEY_NSPhotoLibraryUsageDescription: "Median't shows your photos so you can swipe to keep or delete them. Nothing leaves your phone."`

**Interfaces — Produces:**
- `enum AccessLevel { case notDetermined, full, limited, denied }`
- `struct AlbumInfo: Identifiable, Hashable { let id: String; let title: String; let count: Int; let coverAssetID: String? }`
- `struct AssetInfo: Identifiable, Hashable { let id: String; let aspect: Double /* w/h */; let isVideo: Bool; let duration: TimeInterval }`
- `protocol PhotoLibrary: AnyObject, Sendable { func accessLevel() -> AccessLevel; func requestAccess() async -> AccessLevel; func albums() -> [AlbumInfo]; func assets(inAlbum id: String) -> [AssetInfo] /* newest first */; func fileSize(ofAsset id: String) -> Int64?; func existingIDs(among ids: [String]) -> Set<String>; func delete(_ ids: [String]) async throws }`
- `final class PhotoKitLibrary: PhotoLibrary` — albums = non-empty smart albums (`.smartAlbum`, any subtype) + user albums (`.album`), sorted Recents first then by title; asset fetch sorted by `creationDate` descending; `fileSize` = sum of `PHAssetResource.assetResources(for:)` `value(forKey: "fileSize") as? Int64`.
- `@MainActor @Observable final class AlbumSizes` — `init(library: PhotoLibrary)`; `func size(of albumID: String) -> Int64?`; `var total: Int64?`; `func refresh(_ albums: [AlbumInfo]) async` — computes per-asset sizes off the main actor, caches per asset id, updates each album when done. Missing sizes are skipped in sums.
- `final class ThumbnailLoader` — `func image(for id: String, target: CGSize, contentMode: PHImageContentMode) async -> UIImage?` over `PHCachingImageManager` (opportunistic, network allowed).

- [ ] **Step 1: Failing tests** with `FakePhotoLibrary` (in-memory albums/assets/sizes): `sumsAssetSizes`, `ignoresMissingSizes` (one nil → sum of the rest; all nil → `nil`… show "—"), `totalSumsAlbumsWithoutDoubleCounting` is **not** required — `total` = size of the "Recents" album if present, else sum.
- [ ] **Step 2–4:** red → implement → green.
- [ ] **Step 5:** Commit `feat: photo library access and album sizes`.

### Task 4: App shell, permissions, floating tab bar, Albums page

**Files:**
- Create: `Mediant/App/AppModel.swift`, `Mediant/App/RootView.swift`, `Mediant/App/FloatingTabBar.swift`, `Mediant/App/AccessView.swift`, `Mediant/Albums/AlbumsView.swift`, `Mediant/Albums/AlbumRow.swift`, `Mediant/Shared/Chip.swift`
- Modify: `Mediant/MediantApp.swift`; Delete: `Mediant/ContentView.swift`

**Interfaces — Produces:**
- `@MainActor @Observable final class AppModel` — `library: PhotoLibrary`, `store: DecisionStore` (file in Application Support `decisions.json`), `sizes: AlbumSizes`, `thumbs: ThumbnailLoader`, `var access: AccessLevel`, `var albums: [AlbumInfo]`, `var tab: Tab` (`enum Tab { case albums, trash }`), `func start() async` (request access, load albums, `store.removeMissing`, refresh sizes; reload on `PHPhotoLibraryChangeObserver`).
- `Chip(_ text: String, tint: Color? = nil, action:)` — the glass capsule used for Back / 👹 / Undo / Select / Empty (`.ultraThinMaterial`, 11 pt semibold, height 32).
- `FloatingTabBar(selection: Binding<Tab>, trashCount: Int)` — 86 pt wide, 38 pt tall capsule, two SF Symbols (`photo.on.rectangle`, `trash`), red count badge hidden at 0.
- Albums page: large title "Albums", subtitle "N albums · X", rows (44 pt thumb, title, "N items · X"). `NavigationStack` with `AlbumInfo` destination.

- [ ] **Step 1:** Implement; `run.sh`; grant Photos on the sim (`xcrun simctl privacy <udid> grant photos com.pisarenko.mediant`) and screenshot: albums list with counts and sizes, tab bar at bottom center.
- [ ] **Step 2:** Revoke access (`simctl privacy … revoke photos …`), relaunch → AccessView with "Allow access" / "Open Settings". Re-grant.
- [ ] **Step 3:** Commit `feat: app shell, tab bar and albums page`.

### Task 5: Album grid and swipe screen

**Files:**
- Create: `Mediant/Album/AlbumGridView.swift`, `Mediant/Swipe/SwipeView.swift`, `Mediant/Swipe/PhotoPage.swift`, `Mediant/Swipe/PreviewStrip.swift`, `Mediant/Swipe/SparkleEdge.swift`, `Mediant/Swipe/SparkleShape.swift`

**Interfaces — Consumes:** `SwipeSession`, `AppModel`, `ThumbnailLoader`, `Chip`. **Produces:** `SwipeView(album: AlbumInfo, assets: [AssetInfo], startIndex: Int)` pushed from the grid; hides the tab bar.

Behavior pinned by the spec (exact):
- Grid: 3 columns, 2 pt spacing, square crops, newest first, 👹/💖 corner badges.
- Photo page: aspect < 0.7 → fill; else fit over blurred (radius ~26, brightness −0.55) copy. Video → "▶ m:ss" chip.
- Drag: flat horizontal slide, next photo slides in from the opposite side; commit threshold 90 pt or predicted end > 160 pt; else spring back. Left = `.trashed`, right = `.kept`. Light haptic on commit.
- Sparkles: ~30 per edge, 12–32 pt, ✨-style 4-point concave star (`SparkleShape`, height ≈ 1.6× width), ~35 % as 3-star clusters, twinkle scale 0.4→1.1, opacity 0.3→1, rotation −8°→6°, period 0.9–2.1 s random; edge opacity = min(|dx|/110, 1); red `#ff453a` left, green `#30d158` right, soft glow.
- Strip: thumbs height 36 (current 42, white 2 pt ring), width = height × aspect, 4 pt gap, current centered, animated scroll; 💖/👹 corner badges (11 pt); trashed tiles darkened; newly trashed 👹 animates opacity 0→1 at scale ~3 centered, then shrinks to the corner over 0.6 s. Tap jumps.
- Chips: "‹ Back" top-left, "👹 N" top-right (tap → `app.tab = .trash` and pop to root), "↶ Undo" right above strip (disabled look when `!canUndo`), size label bottom-left above strip.
- Finished → "All done" + "Back to album".

- [ ] **Step 1:** Implement grid; screenshot album grid.
- [ ] **Step 2:** Implement swipe screen; launch, swipe left/right via `control swipe`, screenshot mid-state and after; verify strip badges, counter, undo.
- [ ] **Step 3:** Commit `feat: album grid and swipe screen`.

### Task 6: Trash tab

**Files:** Create `Mediant/Trash/TrashView.swift`, `Mediant/Trash/TrashModel.swift`; Test `MediantTests/TrashModelTests.swift`

**Interfaces — Produces:** `@MainActor @Observable final class TrashModel` — `init(store: DecisionStore, library: PhotoLibrary)`; `var isSelecting: Bool`; `var selection: Set<String>`; `func restoreSelected()`; `func emptyTrash() async` (calls `library.delete(store.trashedIDs)`; on success `store.clearTrash`; on throw leave store unchanged); `var totalBytes: Int64?`.

- [ ] **Step 1: Failing tests** — `emptyTrashClearsOnSuccess`, `emptyTrashKeepsIDsWhenDeleteThrows` (fake throws → trashedIDs unchanged), `restoreSelectedUntrashesAndExitsSelect`.
- [ ] **Step 2–4:** red → implement → green.
- [ ] **Step 5:** View: title "Trash", subtitle "N photos · X to free", 3-col grid with 👹; bottom row on the tab bar line: "Select" (left) / "Empty" red (right); select mode → "Cancel" / "Restore (n)"; empty state text. Screenshot both modes; tap Empty → iOS dialog appears.
- [ ] **Step 6:** Commit `feat: trash tab with batch delete and restore`.

### Task 7: Sample photos, docs, skill

**Files:** Create `.claude/skills/run-sim/scripts/seed-photos.sh`; Modify `.claude/skills/run-sim/SKILL.md`, `CLAUDE.md`

- [ ] **Step 1:** `seed-photos.sh` generates ~40 local images of mixed aspect ratios (portrait/landscape/square/tall) with `sips`/Swift (no downloads) and `xcrun simctl addmedia` them to the dedicated sim; idempotent via a marker file in the sim's data dir.
- [ ] **Step 2:** Document in SKILL.md and CLAUDE.md (architecture map, where things live, PhotoKit-behind-protocol rule, how to grant Photos permission on the sim).
- [ ] **Step 3:** Full `run.sh --test` green; final screenshots of every screen.
- [ ] **Step 4:** Commit `docs: project map, sim seeding`.
