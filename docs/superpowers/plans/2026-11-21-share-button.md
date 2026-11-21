# Share Button Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** A share chip at the top right of the swipe screen and the Trash viewer shares the item's real file.
**Spec:** `docs/superpowers/specs/2026-11-21-share-button-design.md`

## Global Constraints
- Photos only in `PhotoKitLibrary` / `ThumbnailLoader`; logic tested with `FakePhotoLibrary`.
- Every text in `Localizable.xcstrings` with Russian; privacy policy updated in both languages.
- Sim `Median't iPhone 16` only; commits as axyelina; branch `claude/share-button`.

## Review Focus
- The temporary copy is left behind (cancel, failure, sheet closed by swipe).
- A second tap while the file loads starts a second export.
- The share sheet does not appear inside the Trash viewer (a full-screen cover) or appears behind it.
- A failed iCloud load shows no message, or the spinner never stops.
- The privacy text no longer matches the code.

### Task 1: Export and temporary files (TDD)
- Produces: `PhotoLibrary.exportFile(ofAsset id: String, to directory: URL) async throws -> URL`; `final class SharedFiles { init(library:baseDirectory:); func prepare(_ id: String) async throws -> URL; func finish(_ url: URL) }`.
- [ ] Failing tests `SharedFilesTests`: prepare returns an existing file under a new folder in the base directory; finish removes that folder; a failing export throws and leaves no folder.
- [ ] Implement (fake: writes `id.jpg`, can be told to fail); PhotoKit with `PHAssetResourceManager.writeData`.
- [ ] `run.sh --test` passes; commit.

### Task 2: ShareChip, both screens, texts, privacy, docs
- [ ] `ShareChip(id:)` with spinner, alert, UIKit share sheet from the top view controller, `finish` in the completion handler; put it right of the `Spacer` in both top bars.
- [ ] Strings + privacy sentence + "Last updated: November 21, 2026" (both languages); CLAUDE.md code map; design doc.
- [ ] Sim: share a photo, a video and a GIF from the swipe screen and the Trash viewer (sheet opens, preview right); `run.sh --test`; commit.
