#!/usr/bin/env bash
set -euo pipefail

# Generates PNG icons from web/icons/dumbbell.svg
# Requires either `rsvg-convert` (librsvg) or `convert` (ImageMagick) to be installed.

SVG="$(pwd)/web/icons/dumbbell.svg"
OUT_DIR="$(pwd)/web/icons"

if [ ! -f "$SVG" ]; then
  echo "SVG not found at $SVG" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

echo "Generating PNG icons from $SVG into $OUT_DIR"

gen_with_rsvg() {
  rsvg-convert -w "$1" -h "$2" "$SVG" -o "$3"
}

gen_with_convert() {
  convert "$SVG" -resize ${1}x${2} "$3"
}

generate() {
  W=$1; H=$2; OUT=$3
  if command -v rsvg-convert >/dev/null 2>&1; then
    gen_with_rsvg "$W" "$H" "$OUT"
  elif command -v convert >/dev/null 2>&1; then
    gen_with_convert "$W" "$H" "$OUT"
  else
    echo "Neither rsvg-convert nor convert is available. Install librsvg or ImageMagick." >&2
    exit 2
  fi
}

# sizes
generate 512 512 "$OUT_DIR/Icon-512.png"
generate 192 192 "$OUT_DIR/Icon-192.png"
generate 180 180 "$OUT_DIR/Icon-180.png"
# maskable icon (same as 512 but named maskable)
cp "$OUT_DIR/Icon-512.png" "$OUT_DIR/Icon-maskable-512.png" || true

echo "Generated icons:"
ls -l "$OUT_DIR"/Icon-*.png || true

echo "Done. You may need to clear service worker cache and rebuild to see changes in PWA installs."
