#!/usr/bin/env bash
# calcurse-theme.sh
# Translates the active theme's ACCENT hex color into a basic terminal color name
# and writes it as calcurse's appearance.theme setting.
# Called by apply-theme.sh with the current theme.env and calcurse config paths.
set -euo pipefail

# Accept env file and calcurse config paths as arguments, falling back to defaults
ENV="${1:-$HOME/.config/i3/themes/current.env}"
CONF="${2:-$HOME/.config/calcurse/conf}"

# If the env file doesn't exist, exit silently — calcurse theming is optional
[[ -f "$ENV" ]] || exit 0

# Source the env file with -a so every variable is automatically exported.
# This makes ACCENT and other theme vars available to this script.
set -a
# shellcheck disable=SC1090
source "$ENV"
set +a

# Default ACCENT color if the theme doesn't define one
: "${ACCENT:=#1e90d4}"

# ---- hex_to_basic
# Converts a 6-digit hex color (e.g. "#bd93f9") to the closest basic terminal
# color name that calcurse understands: cyan, blue, yellow, red, or green.
# The conversion uses a simple dominant-channel comparison (no perceptual math).
hex_to_basic() {
  local h="${1#\#}"   # strip leading '#'

  # Bail out with a safe default if the value isn't exactly 6 hex digits
  [[ "${#h}" == 6 ]] || { echo cyan; return; }

  # Decode each channel from hex to decimal
  local r=$((16#${h:0:2}))
  local g=$((16#${h:2:2}))
  local b=$((16#${h:4:2}))

  # Determine the dominant channel and map to the nearest named color
  if (( b >= r && b >= g )); then
    # Blue-dominant: high green component pushes it toward cyan
    (( g > 120 )) && echo cyan || echo blue
  elif (( r >= g && r >= b )); then
    # Red-dominant: high green component pushes it toward yellow
    (( g > 150 )) && echo yellow || echo red
  else
    # Green-dominant
    echo green
  fi
}

# Convert the theme's ACCENT hex color to a calcurse-compatible color name
ACCENT_C="$(hex_to_basic "$ACCENT")"

# ---- Write the theme to calcurse's config
# Ensure the config directory exists and the file is present (even if empty)
mkdir -p "$(dirname "$CONF")"
touch "$CONF"

# Update appearance.theme in-place if it already exists, or append it if not
if grep -q '^appearance.theme=' "$CONF"; then
  sed -i "s/^appearance.theme=.*/appearance.theme=${ACCENT_C} on default/" "$CONF"
else
  echo "appearance.theme=${ACCENT_C} on default" >> "$CONF"
fi

echo "OK: calcurse theme -> ${ACCENT_C}"
