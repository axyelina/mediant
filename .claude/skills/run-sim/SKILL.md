---
name: run-sim
description: Build, launch, screenshot or test Median't on its dedicated "Median't iPhone 16" simulator, and seed it with sample photos. Use whenever the user wants to run, see, check or test the app, or before claiming a UI change works.
---

# Run Median't on its simulator

Only ever use the simulator named **`Median't iPhone 16`** (dark appearance). Never target another
simulator, even if one is booted or the panel is attached elsewhere.

1. **Open the panel first** so the user can watch: iOS Simulator `control` → `attach` with
   `device: "Median't iPhone 16"`. If it errors because the sim isn't booted, do step 2 and retry.
2. **Sample photos (first time on a sim):** `.claude/skills/run-sim/scripts/seed-photos.sh`
   draws 40 local images in mixed shapes (portrait, landscape, square, panorama, screenshot-tall)
   plus 4 short videos (`make-videos.swift`: a moving ball inside a white frame, so cropping is easy
   to spot) and adds them with `simctl addmedia`. It runs once per simulator (marker file);
   `--force` adds another batch, `--videos` adds only the videos. No downloads.
3. **Build and launch:** `.claude/skills/run-sim/scripts/run.sh` from the repo root (long
   timeout; a clean build takes a minute or two). The script finds or creates the simulator,
   boots it, sets dark appearance, regenerates the Xcode project if `project.yml` changed, builds
   into `./build`, installs and launches.
4. **Photos permission:** on first launch the app asks for access. `simctl privacy grant` does
   not work on iOS 18.4 here — tap "Allow Full Access" in the simulator.
5. **Verify:** `control` → `screenshot` with the same `device`, and look at it before reporting.
   Wait ~1 s after a tap that pushes a screen, and after `run.sh`, before the next tap — taps sent
   during launch land on the home screen.

Tests: `.claude/skills/run-sim/scripts/run.sh --test` (runs `MediantTests` on the same simulator).
The test run **replaces the running app** with the test host, so relaunch with `run.sh` before
driving the UI again. Failure details are hidden by `-quiet`; on failure, look for
`Failing tests:` and rerun the single test in Xcode or without `-quiet`.

If the script fails, read the xcodebuild error output; don't fall back to another simulator.
