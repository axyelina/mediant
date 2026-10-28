#!/usr/bin/env bash
# Build and launch Median't (or run its tests) on the dedicated "Median't iPhone 16" simulator.
# Creates the simulator if it doesn't exist, boots it, and keeps it in dark appearance.
# Usage: run.sh [--test]
set -euo pipefail

SIM_NAME="Median't iPhone 16"
DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-16"
RUNTIME="com.apple.CoreSimulator.SimRuntime.iOS-18-4"
BUNDLE_ID="com.pisarenko.mediant"

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
cd "$ROOT"

UDID=$(xcrun simctl list devices -j | python3 -c "
import json, sys
name = sys.argv[1]
for devs in json.load(sys.stdin)['devices'].values():
    for d in devs:
        if d['name'] == name and d.get('isAvailable', True):
            print(d['udid']); sys.exit()
" "$SIM_NAME")
if [[ -z "$UDID" ]]; then
  UDID=$(xcrun simctl create "$SIM_NAME" "$DEVICE_TYPE" "$RUNTIME")
  echo "Created simulator $SIM_NAME ($UDID)"
fi

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" >/dev/null
xcrun simctl ui "$UDID" appearance dark

[[ project.yml -nt Mediant.xcodeproj/project.pbxproj ]] && xcodegen generate --quiet

ACTION=build
[[ "${1:-}" == "--test" ]] && ACTION=test

xcodebuild -project Mediant.xcodeproj -scheme Mediant \
  -destination "id=$UDID,arch=arm64" -derivedDataPath build -quiet "$ACTION"

if [[ "$ACTION" == build ]]; then
  xcrun simctl install "$UDID" build/Build/Products/Debug-iphonesimulator/Mediant.app
  xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE_ID" >/dev/null
  echo "Launched $BUNDLE_ID on $SIM_NAME ($UDID)"
else
  echo "Tests passed on $SIM_NAME ($UDID)"
fi
