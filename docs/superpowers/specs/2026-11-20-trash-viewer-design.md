# Trash viewer — design (2026-11-20)

## Why

Before "Empty" the user wants to look at what is in the Trash at full size (a thumbnail is not
enough to be sure), and take a single item back out on the spot.

## What the user gets

- In the Trash grid, a tap on a tile (outside Select mode) opens that item full screen, over
  the tab bar. In Select mode a tap still selects.
- The viewer looks like the swipe screen: the whole photo over a blurred copy (`PhotoPage`); a
  video plays in a loop with the time chip (pause / scrub) and the mute chip.
- Swipe left / right = next / previous Trash item, in the grid order (last trashed first), as a
  carousel. At either end the card gives a little and springs back.
- Swipe right from the left screen edge, or "‹ Back", closes the viewer. Up / down and a tap do
  nothing.
- Bottom row: the size label on the left (and the video chips), a **Restore** chip on the right.
  Restore takes this one item out of the Trash (it becomes undecided, the same as "Restore (n)"),
  with a light haptic. The next item shows (the previous one if it was the last); when the Trash
  is empty, the viewer closes.
- The Trash grid tiles get the video mark the album grid has (`▶ 0:20`).

## Goals / non-goals / anti-goals

- Goal: look, then keep the Trash or restore single items. Fast in thumb reach.
- Non-goal: deleting from the viewer. Deleting stays only `TrashModel.emptyTrash()` (Empty).
- Non-goal: Undo of a restore in the viewer (the item is back in its album; swipe it again).
- Anti-goal: an app-made confirmation, or a new place that deletes.

## Approaches

- **A. Full-screen Trash viewer (chosen).** Its own screen, reusing `PhotoPage`, `LoopingVideo`,
  `VideoChip` and `SwipeGesture`'s next / previous / back. Restore and browse only; no meaning
  conflicts with the swipe screen.
- B. Open the swipe screen on the Trash items (down = restore). Less code, but "up = delete"
  means nothing for a trashed item, and the swipe screen belongs to the Albums tab. Rejected.
- C. One item at a time, no browsing. Simplest, but slow to check many items. Rejected.

## How (builder's calls, marked as mine)

- `PhotoLibrary.assets(withIDs:) -> [AssetInfo]` (in the given order, missing ids left out):
  the Trash keeps only ids, and the viewer needs `isVideo` / `duration` / aspect.
  `PhotoKitLibrary` uses `PHAsset.fetchAssets(withLocalIdentifiers:)`; `FakePhotoLibrary` too.
- `TrashModel.restore(_ id:)` for one item (tested).
- A pure `TrashBrowse.index(afterRestoring:count:)` (Model, tested): the same index while it
  exists, else the last one, nil when nothing is left.
- `TrashViewer` (new, `Mediant/Trash/`): shown with `fullScreenCover` from `TrashView`, dark
  style forced (black screen), its own `VideoPlayback`. The item list follows
  `store.trashedIDs`, so it stays right if the Trash changes.
- New text "Restore" (Russian "Восстановить") in `Localizable.xcstrings`.
- Nothing new leaves the phone: no privacy policy or privacy manifest change.
