---
name: run-device
description: Build, install and launch Median't on a real iPhone (default the phone named "LINK"). Use when the user wants the app on their phone or device, not the simulator.
---

# Run Median't on a real iPhone

1. Check the phone is connected and available: `xcrun devicectl list devices`.
2. Run `.claude/skills/run-device/scripts/run-device.sh [device-name]` (default `LINK`) with a
   long timeout. It builds with automatic signing (`-allowProvisioningUpdates`), installs and
   launches.
3. Exit code 2 = installed but iOS denied the launch (`RequestDenied`): most often the phone is
   locked; on a first install the user must also trust the developer once (Settings › General ›
   VPN & Device Management › Apple Development: … › Trust). Only the user can do this — tell
   them, then run the script again.
   Exit code 3 = installed, but the connection dropped during the launch ("timed out", "tunnel
   was interrupted"; common over Wi-Fi or with the phone locked). The app is on the phone: the
   user can open it by hand, or run the script again with the phone unlocked.
4. Crash on the phone: list the logs with `xcrun devicectl device info files --device <id>
   --domain-type systemCrashLogs`, copy one with `xcrun devicectl device copy from ... --source
   <name>.ips --destination <file>`, and read the faulting thread's frames.

Signing: free **personal team** `NDCC8HH7D8` (Lina Barkhatova), set in `project.yml`. Apps signed
with a free team stop opening after 7 days; run the script again to re-sign. Never switch to
another team (Alexandr Katsz, Prime XBT, Melon Fashion) without asking the user.

The simulator rule in CLAUDE.md still applies to everything else: simulator work uses only
`Median't iPhone 16`.
