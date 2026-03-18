#!/usr/bin/env bash
set -euo pipefail

CFG="$HOME/.config/eww"
EWW="eww -c $CFG"

menu="${1:-}"
[[ -z "$menu" ]] && exit 1

# List ALL menus you use
ALL_WINDOWS=(
  wifi-menu
  bluetooth-menu
  brightness-control
  volume-control
)

# Close everything first (ignore errors if already closed)
for w in "${ALL_WINDOWS[@]}"; do
  $EWW close "$w" >/dev/null 2>&1 || true
done

# Small delay helps avoid race when clicking quickly (optional but nice)
sleep 0.02

# Open requested menu + its backdrop
case "$menu" in
  wifi)
    $EWW open wifi-menu
    ;;
  bluetooth|bt)
    $EWW open bluetooth-menu
    ;;
  brightness|bri)
    $EWW open brightness-control
    ;;
  volume|vol)
    $EWW open volume-control
    ;;
  *)
    echo "Unknown menu: $menu" >&2
    exit 2
    ;;
esac
