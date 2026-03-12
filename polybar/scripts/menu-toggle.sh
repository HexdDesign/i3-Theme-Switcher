#!/usr/bin/env bash
set -euo pipefail

CFG="$HOME/.config/eww"
EWW=(eww -c "$CFG")

# ---- ensure daemon is up ----
if ! "${EWW[@]}" ping >/dev/null 2>&1; then
  pkill -x eww 2>/dev/null || true
  rm -f /run/user/$UID/eww-server_* 2>/dev/null || true
  "${EWW[@]}" daemon >/dev/null 2>&1 &
  sleep 0.15
fi

menu="${1:-}"
[[ -z "$menu" ]] && exit 1

case "$menu" in
  wifi)       MENU_WIN="wifi-menu";            BACKDROP_WIN="wifi-backdrop" ;;
  bluetooth|bt) MENU_WIN="bluetooth-menu";     BACKDROP_WIN="bluetooth-backdrop" ;;
  brightness|bri) MENU_WIN="brightness-control"; BACKDROP_WIN="brightness-backdrop" ;;
  volume|vol) MENU_WIN="volume-control";       BACKDROP_WIN="volume-backdrop" ;;
  *) echo "Unknown menu: $menu" >&2; exit 2 ;;
esac

ALL=(wifi-menu wifi-backdrop bluetooth-menu bluetooth-backdrop brightness-control brightness-backdrop volume-control volume-backdrop)

# If the clicked menu is already open, toggle it off
if "${EWW[@]}" active-windows | grep -q "$MENU_WIN"; then
  "${EWW[@]}" close "$MENU_WIN" "$BACKDROP_WIN" >/dev/null 2>&1 || true
  exit 0
fi

# Otherwise ALWAYS switch: close any open menu, then open the requested one
"${EWW[@]}" close "${ALL[@]}" >/dev/null 2>&1 || true

# Avoid polybar mouse-up click-through instantly closing the new backdrop
sleep 0.12

"${EWW[@]}" open "$BACKDROP_WIN"
"${EWW[@]}" open "$MENU_WIN"
