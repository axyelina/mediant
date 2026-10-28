#!/usr/bin/env bash
# Adds generated sample photos (mixed shapes) to the dedicated "Median't iPhone 16" simulator.
# Runs once per simulator; pass --force to add another batch. Usage: seed-photos.sh [--force] [count]
set -euo pipefail

SIM_NAME="Median't iPhone 16"
HERE="$(cd "$(dirname "$0")" && pwd)"
FORCE=0
[[ "${1:-}" == "--force" ]] && { FORCE=1; shift; }
COUNT="${1:-40}"

UDID=$(xcrun simctl list devices -j | python3 -c "
import json, sys
for devs in json.load(sys.stdin)['devices'].values():
    for d in devs:
        if d['name'] == sys.argv[1] and d.get('isAvailable', True):
            print(d['udid']); sys.exit()
" "$SIM_NAME")
[[ -z "$UDID" ]] && { echo "Simulator $SIM_NAME not found; run run.sh first" >&2; exit 1; }

MARKER="$HOME/Library/Developer/CoreSimulator/Devices/$UDID/data/.mediant-seeded"
if [[ -f "$MARKER" && $FORCE == 0 ]]; then
  echo "Already seeded ($MARKER). Use --force to add more."
  exit 0
fi

xcrun simctl boot "$UDID" 2>/dev/null || true
OUT="$(mktemp -d)"
swift "$HERE/make-photos.swift" "$OUT" "$COUNT"
xcrun simctl addmedia "$UDID" "$OUT"/*.jpg
rm -rf "$OUT"
touch "$MARKER"
echo "Added $COUNT photos to $SIM_NAME"
