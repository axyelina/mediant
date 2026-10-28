#!/usr/bin/env bash
# Build, install and launch Median't on a connected iPhone (default: the one named "LINK").
# Usage: run-device.sh [device-name]
set -euo pipefail

NAME="${1:-LINK}"
BUNDLE_ID="com.pisarenko.mediant"
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
cd "$ROOT"

JSON="$(mktemp)"
xcrun devicectl list devices --json-output "$JSON" >/dev/null
read -r DEVICE UDID < <(python3 -c "
import json, sys
for d in json.load(open(sys.argv[1]))['result']['devices']:
    if d['deviceProperties']['name'] == sys.argv[2]:
        print(d['identifier'], d['hardwareProperties']['udid']); break
" "$JSON" "$NAME")
rm -f "$JSON"
[[ -z "${DEVICE:-}" ]] && { echo "Device \"$NAME\" not found (xcrun devicectl list devices)" >&2; exit 1; }

[[ project.yml -nt Mediant.xcodeproj/project.pbxproj ]] && xcodegen generate --quiet
xcodebuild -project Mediant.xcodeproj -scheme Mediant -configuration Debug \
  -destination "id=$UDID" -derivedDataPath build -allowProvisioningUpdates -quiet build
xcrun devicectl device install app --device "$DEVICE" build/Build/Products/Debug-iphoneos/Mediant.app >/dev/null
if xcrun devicectl device process launch --device "$DEVICE" "$BUNDLE_ID" >/dev/null 2>&1; then
  echo "Launched $BUNDLE_ID on $NAME"
else
  echo "Installed on $NAME, but iOS blocked the launch. On the phone: Settings › General ›" \
       "VPN & Device Management › Apple Development: … › Trust. Then run this again." >&2
  exit 2
fi
