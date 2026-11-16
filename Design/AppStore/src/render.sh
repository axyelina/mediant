#!/usr/bin/env bash
# Renders the App Store screenshots from screenshots.html + the captured screens.
# Usage (from the repo root): Design/AppStore/src/render.sh [en|ru ...]   (default: en)
# Output: Design/AppStore/<lang>/6.9/NN-name.png (1320 × 2868) and <lang>/6.3/NN-name.png (1206 × 2622),
# opaque PNGs (App Store Connect refuses images with an alpha channel).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
NAMES=(01-swipe 02-freed 03-albums 04-trash 05-undo)
LANGS=("$@"); [[ ${#LANGS[@]} == 0 ]] && LANGS=(en)
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

for lang in "${LANGS[@]}"; do
  for size in "6.9:1320:2868" "6.3:1206:2622"; do
    IFS=: read -r label w h <<<"$size"
    out="$ROOT/$lang/$label"; mkdir -p "$out"
    for i in "${!NAMES[@]}"; do
      n=$((i + 1)); name="${NAMES[$i]}"
      "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
        --allow-file-access-from-files --virtual-time-budget=3000 --window-size="$w,$h" \
        --user-data-dir="$TMP/profile" --screenshot="$TMP/shot.png" \
        "file://$HERE/screenshots.html?shot=$n&lang=$lang&w=$w&h=$h" >/dev/null 2>&1
      magick "$TMP/shot.png" -crop "${w}x${h}+0+0" +repage -background '#470112' -alpha remove -alpha off \
        -define png:color-type=2 "$out/$name.png"
      echo "$lang/$label/$name.png  $(magick identify -format '%wx%h' "$out/$name.png")"
    done
  done
done
