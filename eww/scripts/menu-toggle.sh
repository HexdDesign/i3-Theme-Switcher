#!/usr/bin/env bash
set -euo pipefail

CFG="$HOME/.config/eww"
EWW=(eww -c "$CFG")

# ---- hard lock: ignore double-invocations ----
LOCK="/tmp/eww-menu-toggle.lock"
exec 9>"$LOCK"
flock -n 9 || exit 0

# ---- debounce: ignore repeats within 250ms ----
STAMP="/tmp/eww-menu-toggle.stamp"
now_ns="$(date +%s%N)"
last_ns="0"
[[ -f "$STAMP" ]] && last_ns="$(cat "$STAMP" 2>/dev/null || echo 0)"
echo "$now_ns" >"$STAMP"
# 250ms = 250,000,000 ns
if (( now_ns - last_ns < 250000000 )); then
  exit 0
fi

# ---- ensure daemon is up ----
if ! "${EWW[@]}" ping >/dev/null 2>&1; then
  pkill -x eww 2>/dev/null || true
  rm -f /run/user/$UID/eww-server_* 2>/dev/null || true
  "${EWW[@]}" daemon >/dev/null 2>&1 &
  sleep 0.15
fi

menu="${1:-}"
[[ -z "$menu" ]] && exit 1

# Accept either short names OR full window IDs
case "$menu" in
  wifi|wifi-menu)                 MENU_WIN="wifi-menu" ;;
  bluetooth|bt|bluetooth-menu)    MENU_WIN="bluetooth-menu" ;;
  brightness|bri|brightness-control) MENU_WIN="brightness-control" ;;
  volume|vol|volume-control)      MENU_WIN="volume-control" ;;
  *) echo "Unknown menu: $menu" >&2; exit 2 ;;
esac

ALL=(wifi-menu bluetooth-menu brightness-control volume-control)

# Close everything else first
for w in "${ALL[@]}"; do
  [[ "$w" == "$MENU_WIN" ]] && continue
  "${EWW[@]}" close "$w" >/dev/null 2>&1 || true
done

# --- TOGGLE WITHOUT DETECTING STATE ---
# Try to close; if it was open, we're done. If it wasn't open, open it.
"${EWW[@]}" close "$MENU_WIN" >/dev/null 2>&1 && exit 0
"${EWW[@]}" open "$MENU_WIN"  >/dev/null 2>&1

