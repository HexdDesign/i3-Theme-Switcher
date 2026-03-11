#!/usr/bin/env bash
# switch-theme.sh
# Interactive theme picker. Presents available themes via rofi (or dmenu as fallback),
# then calls apply-theme.sh to apply the chosen theme and update related app configs.
set -euo pipefail

# Path to the folder containing all theme subdirectories
I3_THEMES="$HOME/.config/i3/themes"

# Path to the main theme application script
APPLY="$HOME/.config/i3/apply-theme.sh"

# Path to the custom rofi stylesheet for the theme picker UI
PICKER_THEME="$HOME/.config/rofi/theme-picker.rasi"

# notify: send a desktop notification if notify-send is available; otherwise silently skip
notify() { command -v notify-send >/dev/null 2>&1 && notify-send "Theme switcher" "$*"; }

# ---- Discover available themes
# Scan the themes directory for subdirectories that contain a theme.env file.
# Results are sorted alphabetically and stored in the 'themes' array.
mapfile -t themes < <(
  find "$I3_THEMES" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' \
  | sort \
  | while read -r d; do
      [[ -f "$I3_THEMES/$d/theme.env" ]] && echo "$d"
    done
)

# Abort if no valid themes were found
((${#themes[@]})) || { notify "No themes found (missing theme.env) in $I3_THEMES"; exit 1; }

chosen=""

# ---- Theme selection UI
if command -v rofi >/dev/null 2>&1; then
  # rofi is available — use it as the picker

  if [[ -f "$PICKER_THEME" ]]; then
    # Use the custom theme-picker.rasi stylesheet if it exists
    rofi_theme_args=(-theme "$PICKER_THEME")
  else
    # Fall back to rofi's default styling and notify the user
    notify "theme-picker.rasi not found, using default rofi theme"
    rofi_theme_args=()
  fi

  # Temporarily disable exit-on-error so we can capture rofi's exit code.
  # A non-zero exit code means the user dismissed rofi without choosing anything.
  set +e
  chosen="$(printf '%s\n' "${themes[@]}" | rofi -dmenu -i -p "🎨 Theme" "${rofi_theme_args[@]}")"
  rc=$?
  set -e

  # If the user cancelled (non-zero exit), exit cleanly without applying anything
  [[ $rc -ne 0 ]] && exit 0
else
  # rofi not found — fall back to dmenu
  chosen="$(printf '%s\n' "${themes[@]}" | dmenu -i -p "Theme")"
fi

# ---- Sanitise selection
# Strip any leading or trailing whitespace from the chosen name to prevent
# issues with path construction or comparisons (e.g. "  blue-yellow" → "blue-yellow")
chosen="$(echo "${chosen:-}" | sed 's/^[[:space:]]\+//; s/[[:space:]]\+$//')"

# Exit cleanly if the selection is empty (e.g. dmenu dismissed with no choice)
[[ -n "$chosen" ]] || exit 0

# Ensure apply-theme.sh exists and is executable before trying to run it
[[ -x "$APPLY" ]] || { notify "apply-theme.sh not executable: $APPLY"; exit 1; }

# Path to the optional Geany color scheme helper script
GEANY_SWITCH="$HOME/.config/i3/geany-scheme.sh"

# ---- Apply the chosen theme
if "$APPLY" "$chosen"; then
  notify "Switched to $chosen"

  # Update current.env to point at the newly applied theme so --from-current-env
  # works reliably in any script that runs after this point
  ln -sf "$I3_THEMES/$chosen/theme.env" "$I3_THEMES/current.env"

  # Run the Geany scheme switcher for this theme if available.
  # Uses || so a Geany failure never blocks or rolls back the overall theme switch.
  if [[ -x "$GEANY_SWITCH" ]]; then
    "$GEANY_SWITCH" --from-current-env --restart || notify "Geany scheme switch failed (theme still applied)"
  else
    notify "geany-scheme.sh not found/executable; Geany not changed"
  fi
else
  # apply-theme.sh returned a non-zero exit code — notify and propagate the failure
  notify "Failed applying theme: $chosen"
  exit 1
fi
