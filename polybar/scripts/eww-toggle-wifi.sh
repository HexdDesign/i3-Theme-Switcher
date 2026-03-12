#!/usr/bin/env bash
set -euo pipefail

CFG="$HOME/.config/eww"

# Ensure daemon for this config is up
if ! eww -c "$CFG" ping >/dev/null 2>&1; then
  pkill -x eww 2>/dev/null || true
  rm -f /run/user/$UID/eww-server_* 2>/dev/null || true
  eww -c "$CFG" daemon >/dev/null 2>&1 &
  sleep 0.15
fi

if eww -c "$CFG" active-windows | grep -q "wifi-menu"; then
  eww -c "$CFG" close wifi-menu wifi-backdrop
else
  eww -c "$CFG" close bluetooth-menu bluetooth-backdrop brightness-control brightness-backdrop volume-control volume-backdrop 2>/dev/null || true

  # Prevent Polybar click-through (mouse-up hits the new backdrop and closes it)
  sleep 0.15

  eww -c "$CFG" open wifi-backdrop
  eww -c "$CFG" open wifi-menu
fi
