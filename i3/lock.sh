#!/usr/bin/env bash
# lock.sh
# Locks the screen using i3lock-color.
# Takes a blurred screenshot for the lock screen background (falls back to a solid color
# if screenshot tools are unavailable). All colors are loaded from the theme env file
# written by apply-theme.sh, so the lock screen always matches the active theme.
set -euo pipefail

# Ensure a display is available (falls back to :0 if $DISPLAY is unset)
export DISPLAY="${DISPLAY:-:0}"

# have: returns true if the given command exists on PATH
have() { command -v "$1" >/dev/null 2>&1; }

# ---- Load theme colors
# apply-theme.sh writes all LOCK_* color variables to this temp file on every theme switch.
# Source it here so i3lock receives the correct colors for the current theme.
if [[ -f /tmp/i3lock-theme.env ]]; then
  # shellcheck disable=SC1091
  source /tmp/i3lock-theme.env
fi

# Temp file paths for the raw screenshot and blurred version (scoped to this user's UID)
shot="/tmp/i3lock-shot-${UID}.png"
blur="/tmp/i3lock-blur-${UID}.png"

# cleanup: remove temp image files when the script exits (normally or on error)
cleanup() { rm -f "$shot" "$blur"; }
trap cleanup EXIT

# Blur strength passed to ImageMagick (sigma value); configurable via theme.env
LOCK_BLUR="${LOCK_BLUR:-0x8}"

# ---- Capture the screenshot
# Try maim first, then scrot as a fallback.
# If neither is available, fall back to a solid background color instead.
bg_args=()
if have maim; then
  maim -u "$shot"
elif have scrot; then
  scrot -z "$shot"
else
  # No screenshot tool found — use a plain color background
  bg_args=(--color="${LOCK_BG:-1e1f29}")
fi

# ---- Blur the screenshot (if one was taken)
# Try ImageMagick's modern 'magick' binary first, then the legacy 'convert' alias.
# If neither is available, use the unblurred screenshot directly.
if [[ -z "${bg_args[*]:-}" && -f "$shot" ]]; then
  if have magick; then
    magick "$shot" -blur "$LOCK_BLUR" "$blur"
    bg_args=(-i "$blur")
  elif have convert; then
    convert "$shot" -blur "$LOCK_BLUR" "$blur"
    bg_args=(-i "$blur")
  else
    # ImageMagick not found — pass the raw unblurred screenshot to i3lock
    bg_args=(-i "$shot")
  fi
fi

# ---- Launch i3lock-color
# All color values fall back to Dracula-palette defaults if not defined in the theme env.
# exec replaces this shell process with i3lock so there's no dangling parent process.
exec i3lock \
  "${bg_args[@]}" \
  --clock \
  --indicator \
  --time-str="%I:%M" \
  --date-str="%a, %b %d" \
  --inside-color="${LOCK_INSIDE:-00000000}" \          # inner circle fill (transparent)
  --ring-color="${LOCK_RING:-bd93f9ff}" \               # idle ring color
  --keyhl-color="${LOCK_KEYHL:-f8f8f2ff}" \             # ring highlight on keypress
  --bshl-color="${LOCK_BSHL:-ff5555ff}" \               # ring highlight on backspace
  --separator-color="${LOCK_SEPARATOR:-00000000}" \     # separator line (transparent)
  --line-color="${LOCK_LINE:-00000000}" \               # line between ring and fill (transparent)
  --insidever-color="${LOCK_INSIDE_VER:-00000000}" \    # inner fill while verifying
  --ringver-color="${LOCK_RING_VER:-8be9fdff}" \        # ring color while verifying
  --insidewrong-color="${LOCK_INSIDE_WRONG:-00000000}" \ # inner fill on wrong password
  --ringwrong-color="${LOCK_RING_WRONG:-ff5555ff}" \    # ring color on wrong password
  --time-color="${LOCK_TIME_COLOR:-f8f8f2ff}" \         # clock time text color
  --date-color="${LOCK_DATE_COLOR:-bd93f9ff}" \         # clock date text color
  --verif-color="${LOCK_VERIF_COLOR:-8be9fdff}" \       # verification message text color
  --wrong-color="${LOCK_WRONG_COLOR:-ff5555ff}" \       # wrong password message text color
  --layout-color="${LOCK_LAYOUT_COLOR:-f8f8f2ff}"       # keyboard layout indicator color
