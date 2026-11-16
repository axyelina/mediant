# Vertical swipe on the swipe screen — design (short)

Date: 2026-11-17. Status: approved by the user in chat.

## Intent

Swiping left/right (Tinder style) is less convenient than moving the photo along the thumb's
natural line. New gestures on the swipe screen:

- **Up** (the photo goes away from you) = delete (👹).
- **Down** (the photo comes towards you) = keep.
- **Right** (a horizontal swipe, finger moves right, anywhere on the photo) = back to the album,
  the same as the "‹ Back" chip.

## Goals

- Up/down decide; the old left/right decisions are gone.
- The photo follows the finger only vertically, with no tilt. The next photo waits behind it,
  smaller and darker, and comes forward as the top one leaves (as now).
- A decided photo flies off the top (delete) or the bottom (keep). Undo brings it back from the
  edge where it left.
- Commit thresholds as today: past 90 pt, or a fling whose predicted end is past 160 pt. A
  shorter drag springs back.
- The direction counts by the bigger axis: a mostly vertical drag decides; a mostly horizontal
  drag to the right (same thresholds) goes back to the album; a horizontal drag to the left does
  nothing.
- Sparkle edges move to the top (delete, `#470112`) and the bottom (keep, `#75013d`), with the
  same fade with the finger.
- Texts (English + Russian): "Swipe up to delete, down to keep. …" on the access screen,
  "Swipe up on photos you don't want." on the empty Trash.

## Non-goals

- The 💖 / 👹 badges, the "Don't show 💖" button and the preview strip do not change.
- No second (horizontal) way to decide.

## Removed

- Tap on the photo to skip it. `SwipeSession.skip()` then has no caller and goes, with its tests.

## Approaches

1. **Vertical only, horizontal right = back (chosen).** One axis decides, so a diagonal drag
   never shows a direction it does not mean.
2. Keep left/right as a second way to decide — rejected: the user wants up/down only.
3. Free 2-D card movement — rejected: a diagonal drag would show a misleading direction.

## How

- A pure `SwipeGesture.outcome(translation:predictedEnd:)` in `Model/` (like `TabSwipe`) returns
  trash / keep / back / none; unit-tested first.
- `SwipeView` uses a `dragY` instead of `dragX`; `SparkleEdge` gets `.top` / `.bottom` sides.
- Docs: the main spec's swipe-screen section and `CLAUDE.md` (intro line, code map).

## Left to the builder

- The exact sparkle band depth at the top and bottom (same feel as the side bands).
