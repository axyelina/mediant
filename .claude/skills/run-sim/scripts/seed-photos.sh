#!/usr/bin/env bash
# Adds generated sample photos and videos (mixed shapes) to the dedicated "Median't iPhone 16" simulator.
# Runs once per simulator; pass --force to add another batch, --videos to add only the sample videos,
# --gifs to add only the sample GIF.
# Usage: seed-photos.sh [--force | --videos | --gifs] [count]
set -euo pipefail

SIM_NAME="Median't iPhone 16"
HERE="$(cd "$(dirname "$0")" && pwd)"
FORCE=0
VIDEOS_ONLY=0
GIFS_ONLY=0
[[ "${1:-}" == "--force" ]] && { FORCE=1; shift; }
[[ "${1:-}" == "--videos" ]] && { VIDEOS_ONLY=1; shift; }
[[ "${1:-}" == "--gifs" ]] && { GIFS_ONLY=1; shift; }
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
xcrun simctl boot "$UDID" 2>/dev/null || true
OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT

if [[ $VIDEOS_ONLY == 1 ]]; then
  swift "$HERE/make-videos.swift" "$OUT"
  xcrun simctl addmedia "$UDID" "$OUT"/*.mp4
  echo "Added sample videos to $SIM_NAME"
  exit 0
fi

if [[ $GIFS_ONLY == 1 ]]; then
  swift "$HERE/make-gif.swift" "$OUT" >/dev/null
  xcrun simctl addmedia "$UDID" "$OUT"/*.gif
  echo "Added the sample GIF to $SIM_NAME"
  exit 0
fi

if [[ -f "$MARKER" && $FORCE == 0 ]]; then
  echo "Already seeded ($MARKER). Use --force to add more."
  exit 0
fi

swift "$HERE/make-photos.swift" "$OUT" "$COUNT"
swift "$HERE/make-videos.swift" "$OUT"
swift "$HERE/make-gif.swift" "$OUT" >/dev/null
xcrun simctl addmedia "$UDID" "$OUT"/*.jpg "$OUT"/*.mp4 "$OUT"/*.gif
touch "$MARKER"
echo "Added $COUNT photos, sample videos and a GIF to $SIM_NAME"
