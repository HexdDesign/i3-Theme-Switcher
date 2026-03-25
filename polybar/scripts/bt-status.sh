#!/usr/bin/env bash

# Print an icon (or text) so Polybar always has something to show.
# Also handles cases where bluetoothctl errors out.

if ! command -v bluetoothctl >/dev/null 2>&1; then
  echo "BT?"
  exit 0
fi

powered="$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/ {print $2; exit}')"

case "$powered" in
  yes) echo "󰂯" ;;  # Bluetooth ON
  no)  echo "󰂲" ;;  # Bluetooth OFF
  *)   echo "BT"  ;;  # Fallback if output is weird
esac
