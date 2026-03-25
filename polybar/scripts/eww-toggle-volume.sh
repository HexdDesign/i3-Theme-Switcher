#!/usr/bin/env bash
set -euo pipefail

CFG="$HOME/.config/eww"
EWW="$(command -v eww || true)"
[[ -x "${EWW:-}" ]] || exit 1

# Ensure daemon is running for this config
if ! "$EWW" -c "$CFG" ping >/dev/null 2>&1; then
  pkill -x eww 2>/dev/null || true
  rm -f /run/user/$UID/eww-server_* 2>/dev/null || true
  "$EWW" -c "$CFG" daemon >/dev/null 2>&1 &
  sleep 0.15
fi

if "$EWW" -c "$CFG" active-windows | grep -q "volume-control"; then
  "$EWW" -c "$CFG" close volume-control volume-backdrop
else
  "$EWW" -c "$CFG" close wifi-menu wifi-backdrop bluetooth-menu bluetooth-backdrop brightness-control brightness-backdrop 2>/dev/null || true

  # Prevent Polybar click-through closing the backdrop instantly
  sleep 0.15

  "$EWW" -c "$CFG" open volume-backdrop
  "$EWW" -c "$CFG" open volume-control
fi
