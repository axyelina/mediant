# Share button — design (2026-11-21)

## Why

The user wants to send a photo or video to someone (or save it elsewhere) while looking at it
full screen, without leaving the app.

## What the user gets

- A small glass share chip (`square.and.arrow.up`) at the top right of the swipe screen and of
  the Trash viewer, on the same line as "‹ Back".
- A tap shows a spinner in the chip while the file loads, then the iOS share sheet opens.
- It shares the item as it is in Photos: the edited version when there is one, else the
  original. A video stays a video, a GIF still moves, full quality.
- If the file cannot load (for example an iCloud item with no network), an alert says so.
- Sharing decides nothing (no 💖 / 👹) and adds no Undo step.

## Goals / non-goals / anti-goals

- Goal: share the real file, one item at a time.
- Non-goal: sharing several items, sharing from the grids.
- Anti-goal: a copy that stays on the phone; anything sent without the user choosing it.

## Approaches

- **A. Export the file, then `UIActivityViewController` (chosen).** `PHAssetResourceManager`
  writes the item's file into a temporary folder; the share sheet gets the file URL; the folder
  is deleted when the sheet closes. Shows a spinner while it loads.
- B. SwiftUI `ShareLink` with a lazy `Transferable`. No spinner, and it needs a fixed file type
  per item (HEIC / JPEG / GIF / MOV vary). Rejected.
- C. Share the picture on screen (`UIImage`). Loses video, GIF motion and quality. Rejected.

## How (builder's calls, marked as mine)

- `PhotoLibrary.exportFile(ofAsset:to:) async throws -> URL`: `PhotoKitLibrary` picks
  `.fullSizeVideo` / `.video` or `.fullSizePhoto` / `.photo` and writes it with its original file
  name, iCloud download allowed. `FakePhotoLibrary` writes a small file.
- `SharedFiles` (Model, tested with the fake): `prepare(_ id:) async throws -> URL` makes a new
  folder under the temporary folder and exports into it (no folder left after a failure);
  `finish(_ url:)` deletes that folder.
- `ShareChip` (`Mediant/Shared/`): the chip, the spinner, the alert, and the UIKit presentation
  of the share sheet from the top view controller; cleanup in the sheet's completion handler.
- Texts (English + Russian): "Share" (accessibility label), "Couldn't share", the alert text.
- Privacy policy: a new sentence in the "reads your library" paragraph and a new
  "Last updated" date; `PrivacyInfo.xcprivacy` unchanged (no new data type, no required-reason
  API).
