---
name: run-device
description: Build, install and launch Median't on a real iPhone (default the phone named "LINK"). Use when the user wants the app on their phone or device, not the simulator.
---

# Run Median't on a real iPhone

1. Check the phone is connected and available: `xcrun devicectl list devices`.
2. Run `.claude/skills/run-device/scripts/run-device.sh [device-name]` (default `LINK`) with a
   long timeout. It builds with automatic signing (`-allowProvisioningUpdates`), installs and
   launches.
3. Exit code 2 = installed but iOS blocked the launch: the user must trust the developer once on
   the phone (Settings › General › VPN & Device Management › Apple Development: … › Trust). Only
   the user can do this — tell them, then run the script again.

Signing: free **personal team** `WZHN8Q7J25` (Alexandr Katsz), set in `project.yml`. Apps signed
with a free team stop opening after 7 days; run the script again to re-sign. Never switch to a
company team (Prime XBT, Melon Fashion) without asking the user.

The simulator rule in CLAUDE.md still applies to everything else: simulator work uses only
`Median't iPhone 16`.
