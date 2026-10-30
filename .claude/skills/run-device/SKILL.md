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
4. Sandbox tip check: always install with `run-device.sh` (devicectl). A Run from Xcode, also on
   the phone, uses the scheme's local StoreKit file `MediantTests/Tips.storekit`, not sandbox.
5. Crash on the phone: list the logs with `xcrun devicectl device info files --device <id>
   --domain-type systemCrashLogs`, copy one with `xcrun devicectl device copy from ... --source
   <name>.ips --destination <file>`, and read the faulting thread's frames.

Signing: paid individual team `NDCC8HH7D8` (Angelina Odegova), set in `project.yml`; identity
"Apple Development: Angelina Odegova". Development profiles last a year. Never switch to another
team (Alexandr Katsz, Prime XBT, Melon Fashion) without asking the user. The "Apple Development:
Lina Barkhatova" certificate in the keychain belongs to Melon Fashion, not to this team.

The simulator rule in CLAUDE.md still applies to everything else: simulator work uses only
`Median't iPhone 16`.
