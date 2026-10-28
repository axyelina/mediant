---
name: run-sim
description: Build, launch, screenshot or test Median't on its dedicated "Median't iPhone 16" simulator. Use whenever the user wants to run, see, check or test the app, or before claiming a UI change works.
---

# Run Median't on its simulator

Only ever use the simulator named **`Median't iPhone 16`** (dark appearance). Never target another
simulator, even if one is booted or the panel is attached elsewhere.

1. **Open the panel first** so the user can watch: iOS Simulator `control` → `attach` with
   `device: "Median't iPhone 16"`. If it errors because the sim isn't booted, do step 2 and retry.
2. **Build and launch:** run `.claude/skills/run-sim/scripts/run.sh` from the repo root (run in
   the background or with a long timeout; a clean build takes a minute or two). The script
   finds or creates the simulator, boots it, sets dark appearance, regenerates the Xcode project
   if `project.yml` changed, builds into `./build`, installs and launches.
3. **Verify:** `control` → `screenshot` with the same `device`, and look at it before reporting.

Tests: `.claude/skills/run-sim/scripts/run.sh --test` (runs `MediantTests` on the same simulator).

If the script fails, read the xcodebuild error output; don't fall back to another simulator.
