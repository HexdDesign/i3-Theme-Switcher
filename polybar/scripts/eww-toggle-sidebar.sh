#!/usr/bin/env bash
set -euo pipefail

EWW="/usr/bin/eww"
CFG="$HOME/.config/eww"
WIN="sidebar"

export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"

# start daemon if needed (your state script already does this, but click script must too)
if ! "$EWW" -c "$CFG" ping >/dev/null 2>&1; then
  "$EWW" -c "$CFG" daemon >/dev/null 2>&1 &
  sleep 0.15
fi

if "$EWW" -c "$CFG" active-windows 2>/dev/null | grep -q "^${WIN}:"; then
  exec "$EWW" -c "$CFG" close "$WIN"
else
  exec "$EWW" -c "$CFG" open "$WIN"
fi
