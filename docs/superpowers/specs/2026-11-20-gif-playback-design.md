# GIF playback — design (2026-11-20)

## Why

A GIF in the library shows as a still picture, so the user cannot see what it is before they
keep or delete it. It must move where the user looks at one item full screen.

## What the user gets

- A GIF plays in a loop, at its own frame times, on the swipe screen card (opened from an
  album) and in the Trash viewer. Only the item on screen plays.
- Until its data is loaded, the still picture shows (as a video shows its poster frame).
- On the swipe screen the GIF stops while the Trash tab covers the screen, and plays again when
  the user comes back (the same as a video).
- The album grid and the Trash grid show a still picture with a small `GIF` mark at the bottom
  left (where a video has `▶ 0:20`).
- No chips for a GIF (no pause, no sound): it is a few seconds long and has no sound.

## Goals / non-goals / anti-goals

- Goal: see the GIF move before deciding. Low memory, also for a big GIF.
- Non-goal: moving tiles in the grids (battery, scrolling).
- Non-goal: Live Photos (a separate TODO item).
- Anti-goal: a download, a converted file on disk, or a new permission.

## Approaches

- **A. ImageIO `CGAnimateImageDataWithBlock` (chosen).** Plays the original data frame by frame
  with each frame's own time and the loop count; one frame in memory at a time.
- B. `UIImage.animatedImage(with:duration:)`. Simpler, but one time for all frames (wrong speed)
  and every frame decoded at once (memory). Rejected.
- C. Convert to a video and reuse `LoopingVideo`. Gets the chips, but slow and needs a temporary
  file per GIF. Rejected.

## How (builder's calls, marked as mine)

- `AssetInfo.isAnimated` (default `false`), from `PHAsset.playbackStyle == .imageAnimated` in
  `PhotoKitLibrary`.
- `ThumbnailLoader.imageData(for:) async -> Data?` (`requestImageDataAndOrientation`, network
  allowed as for videos: iCloud is already in the privacy policy, so no policy change).
- `AnimatedImage` (Model, pure, tested with a GIF made in the test): `frameCount(of: Data) -> Int`;
  only data with more than one frame is animated, else the still picture stays.
- `AnimatedImageView` (`Mediant/Shared/`): a `UIViewRepresentable` image view that runs
  `CGAnimateImageDataWithBlock` while it is on screen and stops it when it goes away or is
  paused; it takes no touches. `PhotoPage` puts it over the still picture when
  `plays && asset.isAnimated`; the swipe screen passes "paused" while the Trash tab covers it.
- Grid mark `GIF` in `AlbumGridView` and `TrashView`, same style as the video mark.
- Sample data: `make-gif.swift` (a moving ball, drawn in code, no download) and
  `seed-photos.sh --gifs`.
- Plays with Reduce Motion on too: it is the user's own content, as in the Photos app.
