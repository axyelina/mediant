# GIF Playback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** GIFs play full screen on the swipe screen and in the Trash viewer; grids mark them `GIF`.

**Architecture:** PhotoKit tells which assets are animated; `ThumbnailLoader` loads the original data; a pure `AnimatedImage.frameCount(of:)` decides whether to animate; `AnimatedImageView` plays the data with ImageIO `CGAnimateImageDataWithBlock` over the still picture in `PhotoPage`.

**Tech Stack:** SwiftUI + UIKit representable, ImageIO, PhotoKit behind `PhotoLibrary` / `ThumbnailLoader`, Swift Testing.

**Spec:** `docs/superpowers/specs/2026-11-20-gif-playback-design.md`

## Global Constraints

- Only `PhotoKitLibrary` / `ThumbnailLoader` import Photos.
- No new permission, no download of our own, no file on disk; privacy policy unchanged (iCloud already covered).
- Build / test only on `Median't iPhone 16` with `.claude/skills/run-sim/scripts/run.sh [--test]`; `xcodegen generate` after adding files; commit `project.pbxproj` with them.
- Commits as `axyelina <axyelina@gmail.com>`, Co-Authored-By line; branch `claude/gif-playback`.

## Review Focus

- A GIF on the swipe screen keeps animating while the Trash tab covers it (must stop, and play again on return).
- The animation keeps running after its view is gone (the ImageIO block must stop on dismantle / cancel).
- A one-frame "GIF" or a still image marked animated: shows the still picture, no blank frame.
- A big GIF from iCloud: data loads late or not at all; the still picture stays, no crash.
- The side card in a carousel drag (swipe screen and Trash viewer) does not play; only the current one.

---

### Task 1: Animated assets in the model and loader

**Files:**
- Modify: `Mediant/Library/PhotoLibrary.swift` (`AssetInfo`), `Mediant/Library/PhotoKitLibrary.swift`, `Mediant/Library/ThumbnailLoader.swift`
- Create: `Mediant/Model/AnimatedImage.swift`, `MediantTests/AnimatedImageTests.swift`

**Interfaces:**
- Produces: `AssetInfo.isAnimated: Bool` (`var`, default `false`); `enum AnimatedImage { static func frameCount(of data: Data) -> Int }` (0 for data ImageIO cannot read); `ThumbnailLoader.imageData(for id: String) async -> Data?`.

- [ ] **Step 1: Failing tests** in `AnimatedImageTests` (make the data in the test with `CGImageDestination`): a 3-frame GIF → `3`; a 1-frame PNG → `1`; `Data("nope".utf8)` → `0`.
- [ ] **Step 2:** `run.sh --test` → compile error (no `AnimatedImage`).
- [ ] **Step 3: Implement** `frameCount` with `CGImageSourceCreateWithData` / `CGImageSourceGetCount`; `isAnimated` from `asset.playbackStyle == .imageAnimated` in the shared `infos` helper; `imageData` with `requestImageDataAndOrientation`, `isNetworkAccessAllowed = true`, `deliveryMode = .highQualityFormat`, `version = .original`.
- [ ] **Step 4:** `run.sh --test` → "Tests passed".
- [ ] **Step 5:** `xcodegen generate`; commit `feat: animated assets and GIF frame count` (with `project.pbxproj`).

### Task 2: Play GIFs full screen, mark them in grids, sample GIF

**Files:**
- Create: `Mediant/Shared/AnimatedImageView.swift`, `.claude/skills/run-sim/scripts/make-gif.swift`
- Modify: `Mediant/Swipe/PhotoPage.swift`, `Mediant/Album/AlbumGridView.swift`, `Mediant/Trash/TrashView.swift`, `.claude/skills/run-sim/scripts/seed-photos.sh`, `.claude/skills/run-sim/SKILL.md`, `CLAUDE.md`, `docs/superpowers/specs/2026-10-28-mediant-photo-cleaner-design.md`

**Interfaces:**
- Consumes: Task 1.
- Produces: `AnimatedImageView(id: String)` — loads data, animates only if `frameCount > 1`, pauses while `VideoPlayback.isHidden` (environment, the swipe screen's Trash-tab state), stops on disappear; `PhotoPage` shows it over the still picture when `plays && asset.isAnimated`.

- [ ] **Step 1: View.** UIImageView representable, aspect-fit, no hit testing; start `CGAnimateImageDataWithBlock` in a coordinator, the block sets `stop` when the coordinator is stopped or the view is dismantled. Optional `VideoPlayback` from the environment (the Trash viewer has one too; never hidden there).
- [ ] **Step 2: Grid marks.** `GIF` text, same font / shadow / padding as the video mark, for `asset.isAnimated` (album) and `infos[id]?.isAnimated` (Trash).
- [ ] **Step 3: Sample GIF.** `make-gif.swift <outdir>`: a 12-frame ball moving in a frame, 0.08 s per frame, looping, written with ImageIO; `seed-photos.sh --gifs` adds only it (also add it to a normal seed run); SKILL.md lists `--gifs`.
- [ ] **Step 4: Docs.** CLAUDE.md code map (`Model/` AnimatedImage, `Shared/` AnimatedImageView, run-sim seed line); design doc swipe-screen and grid notes.
- [ ] **Step 5: Verify on the sim.** `seed-photos.sh --gifs`; `run.sh`; the GIF tile shows `GIF`; on the swipe screen it moves; Trash it and open it in the Trash viewer: it moves; on the swipe screen tap 👹 then go back: it moves again; `run.sh --test` passes.
- [ ] **Step 6:** Commit `feat: play GIFs full screen, GIF mark in grids`.
