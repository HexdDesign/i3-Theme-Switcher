#!/usr/bin/env bash
# ~/.config/polybar/scripts/eww-sidebar-state.sh
set -euo pipefail

EWW="/usr/bin/eww"
CFG="$HOME/.config/eww"
WIN="${1:-sidebar}"

THEME_ENV="$HOME/.config/i3/themes/current.env"

# Load theme variables if present
if [[ -f "$THEME_ENV" ]]; then
  # shellcheck disable=SC1090
  source "$THEME_ENV"
fi

# Theme colors (fallbacks if theme doesn't define them)
COLOR_OPEN="%{F${POLYBAR_ACCENT:-#10E8FF}}"
COLOR_CLOSED="%{F${POLYBAR_DIM:-#6B7C8F}}"
RESET="%{F-}"

ICON_CLOSED="${COLOR_CLOSED}${RESET}"
ICON_OPEN="${COLOR_OPEN}${RESET}"

export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"

start_eww_if_needed() {
  if ! "$EWW" -c "$CFG" ping >/dev/null 2>&1; then
    "$EWW" -c "$CFG" daemon >/dev/null 2>&1 &
    sleep 0.15
  fi
}

is_open() {
  [[ "$("$EWW" -c "$CFG" get sidebar_open 2>/dev/null || echo false)" == "true" ]]
}

start_eww_if_needed

# Initial state so polybar allocates width
if is_open; then
  last="$ICON_OPEN"
else
  last="$ICON_CLOSED"
fi
echo "$last"

# Update loop
while :; do
  if is_open; then
    cur="$ICON_OPEN"
  else
    cur="$ICON_CLOSED"
  fi

  if [[ "$cur" != "$last" ]]; then
    echo "$cur"
    last="$cur"
  fi

  sleep 0.25
done
