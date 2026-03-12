#!/usr/bin/env bash
set -euo pipefail

# Outputs ONLY an icon (no scale/bar)
# Low: 󰃞  Med: 󰃟  High: 󰃠

bri="$(brightnessctl -m 2>/dev/null | awk -F',' '{gsub(/%/,"",$4); print $4}')"

if [[ -z "${bri:-}" ]]; then
  echo "󰃠"
  exit 0
fi

if (( bri <= 30 )); then
  echo "󰃞"
elif (( bri <= 70 )); then
  echo "󰃟"
else
  echo "󰃠"
fi
