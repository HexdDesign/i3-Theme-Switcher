#!/usr/bin/env bash
# apply-theme.sh
# Main theme application script. Called by switch-theme.sh with a theme name as argument.
# Applies the chosen theme across all configured apps and components.
set -euo pipefail

# Ensure a display is available (falls back to :0 if $DISPLAY is unset)
export DISPLAY="${DISPLAY:-:0}"

# Accept theme name as first argument, defaulting to "blue-yellow" if none given
THEME="${1:-blue-yellow}"

# ---- Path definitions
# Define base directories for each app's theme files
I3_THEMES="$HOME/.config/i3/themes"
BAR_THEMES="$HOME/.config/polybar/themes"
KITTY_THEMES="$HOME/.config/kitty/themes"
ROFI_THEMES="$HOME/.config/rofi/themes"
NEOFETCH_THEMES="$HOME/.config/neofetch/themes"
WALLPAPERS="$HOME/.config/i3/wallpapers"

# EWW (Elkowar's Wacky Widgets) binary and config paths
EWW_BIN="/usr/bin/eww"
EWW_CONFIG="$HOME/.config/eww"

# Resolve the full path to this theme's directory and its env file
THEME_DIR="$I3_THEMES/$THEME"
THEME_ENV="$THEME_DIR/theme.env"


# ---- Helper functions

# die: print an error to stderr and exit with failure
die() {
  echo "ERROR: $*" >&2
  exit 1
}

# warn: print a non-fatal warning to stderr and continue
warn() {
  echo "WARNING: $*" >&2
}

# safe_symlink: create a symlink from src to dst, but only if src actually exists
# Prints a warning and skips silently if the source file is missing
safe_symlink() {
  local src="$1" dst="$2"
  if [[ -e "$src" ]]; then
    ln -sf "$src" "$dst"
    echo "OK: $dst -> $src"
  else
    warn "missing, skipping symlink: $src"
  fi
}

# Abort early if the chosen theme has no theme.env config file
[[ -f "$THEME_ENV" ]] || die "theme.env not found for theme '$THEME': $THEME_ENV"

# Load all variables defined in theme.env into the current shell environment
# shellcheck disable=SC1090
source "$THEME_ENV"

# Point current.env at this theme immediately so other scripts can read it
# even if something later in this script fails
ln -sf "$THEME_ENV" "$I3_THEMES/current.env"
echo "OK: current.env -> $THEME_ENV"

# ---- Calcurse theme sync (valid keys only)
# If the calcurse theme helper script exists, apply the current theme to calcurse's config
if [[ -x "$HOME/.config/i3/calcurse-theme.sh" ]]; then
  "$HOME/.config/i3/calcurse-theme.sh" "$I3_THEMES/current.env" "$HOME/.config/calcurse/conf" || true
fi

# Debug output: confirm which theme and Geany scheme were loaded
echo "DEBUG: loaded theme.env: THEME=$THEME GEANY_SCHEME='${GEANY_SCHEME:-}'" >&2

# ---- Core symlinks
# Point each app's "current theme" symlink at the correct file for this theme
safe_symlink "$THEME_DIR/$THEME.conf"       "$I3_THEMES/current_theme.conf"
safe_symlink "$BAR_THEMES/$THEME.ini"       "$BAR_THEMES/current_theme.ini"
safe_symlink "$KITTY_THEMES/$THEME.conf"    "$KITTY_THEMES/current_theme.conf"
safe_symlink "$NEOFETCH_THEMES/$THEME.conf" "$HOME/.config/neofetch/config.conf"

# ---- Rofi
# Create the rofi app-themes directory if it doesn't exist, then symlink the current theme
ROFI_APP_THEMES="$HOME/.config/rofi/app-themes"
mkdir -p "$ROFI_APP_THEMES"
safe_symlink "$ROFI_THEMES/$THEME.rasi" "$ROFI_APP_THEMES/current.rasi"

# Update the icon theme name in rofi's app-launcher config via sed in-place replacement
if [[ -n "${ICON_THEME:-}" ]]; then
  sed -i "s|icon-theme:.*|icon-theme:  \"$ICON_THEME\";|" \
    "$HOME/.config/rofi/app-launcher.rasi"
  echo "OK: rofi icon-theme -> $ICON_THEME"
else
  warn "ICON_THEME not set, skipping rofi icon-theme patch"
fi

# Symlink the rofi background image for this theme (uses ROFI_IMAGE from theme.env if set,
# otherwise falls back to the conventional path based on theme name)
if [[ -f "${ROFI_IMAGE:-$HOME/.config/rofi/images/$THEME.png}" ]]; then
  ln -sf "${ROFI_IMAGE:-$HOME/.config/rofi/images/$THEME.png}" \
    "$HOME/.config/rofi/images/current_image.png"
  echo "OK: rofi image -> ${ROFI_IMAGE:-$HOME/.config/rofi/images/$THEME.png}"
else
  warn "no rofi image for theme '$THEME'"
fi

# ---- GTK theme + icon theme via gsettings
# Read GTK and icon theme names from the loaded theme.env variables
gtk_name="${GTK_THEME:-}"
icon_name="${ICON_THEME:-}"

# Track whether each theme directory was actually found on disk
gtk_ok=false
icon_ok=false

# Standard locations where GTK and icon themes can be installed
gtk_paths=("$HOME/.themes" "$HOME/.local/share/themes" "/usr/share/themes")
icon_paths=("$HOME/.icons" "$HOME/.local/share/icons" "/usr/share/icons")

# Check each possible GTK theme path until a match is found
if [[ -n "$gtk_name" ]]; then
  for p in "${gtk_paths[@]}"; do
    [[ -d "$p/$gtk_name" ]] && gtk_ok=true && break
  done
fi

# Check each possible icon theme path until a match is found
if [[ -n "$icon_name" ]]; then
  for p in "${icon_paths[@]}"; do
    [[ -d "$p/$icon_name" ]] && icon_ok=true && break
  done
fi

# Apply GTK and icon themes via gsettings if they were found on disk
[[ "$gtk_ok"  == true ]] && gsettings set org.gnome.desktop.interface gtk-theme  "$gtk_name"  2>/dev/null || true
[[ "$icon_ok" == true ]] && gsettings set org.gnome.desktop.interface icon-theme "$icon_name" 2>/dev/null || true
# Warn if a theme was configured in theme.env but the directory doesn't exist
[[ -n "$gtk_name"  && "$gtk_ok"  != true ]] && warn "GTK theme not found: $gtk_name"
[[ -n "$icon_name" && "$icon_ok" != true ]] && warn "icon theme not found or missing index.theme: $icon_name"

# ---- Update xsettingsd config
# xsettingsd is a lightweight settings daemon that propagates theme changes to X11 apps
XSETTINGS="$HOME/.xsettingsd"

# Update or append the icon theme name in the xsettingsd config file
if [[ -n "$icon_name" && "$icon_ok" == true ]]; then
  if grep -q 'Net/IconThemeName' "$XSETTINGS" 2>/dev/null; then
    sed -i "s|Net/IconThemeName.*|Net/IconThemeName \"$icon_name\"|" "$XSETTINGS"
  else
    echo "Net/IconThemeName \"$icon_name\"" >> "$XSETTINGS"
  fi
fi

# Update or append the GTK theme name in the xsettingsd config file
if [[ -n "$gtk_name" && "$gtk_ok" == true ]]; then
  if grep -q 'Net/ThemeName' "$XSETTINGS" 2>/dev/null; then
    sed -i "s|Net/ThemeName.*|Net/ThemeName \"$gtk_name\"|" "$XSETTINGS"
  else
    echo "Net/ThemeName \"$gtk_name\"" >> "$XSETTINGS"
  fi
fi

# Reload xsettingsd with SIGHUP to apply changes, or start it fresh if it's not running
if command -v xsettingsd >/dev/null 2>&1; then
  pkill -HUP xsettingsd 2>/dev/null || (xsettingsd >/dev/null 2>&1 &)
fi

# ---- GTK3 settings.ini
# Write a fresh GTK3 settings file using values from theme.env
mkdir -p "$HOME/.config/gtk-3.0/current"

cat > "$HOME/.config/gtk-3.0/settings.ini" <<EOF
[Settings]
gtk-theme-name=${GTK_THEME:-}
gtk-icon-theme-name=${ICON_THEME:-}
gtk-font-name=${GTK_FONT:-Sans 10}
gtk-cursor-theme-name=${CURSOR_THEME:-default}
gtk-application-prefer-dark-theme=1
EOF

echo "OK: gtk-3.0/settings.ini updated"

# ---- GTK3 CSS router
# Write a master gtk.css that imports per-theme CSS overrides from the "current/" subfolder.
# This allows app-specific overrides (Thunar, Geany) without touching the main GTK stylesheet.
cat > "$HOME/.config/gtk-3.0/gtk.css" <<'EOF'
/* Auto-generated by apply-theme.sh (GTK3 router) */
@import url("current/gtk.css");
@import url("current/thunar.css");
@import url("current/geany.css");
EOF

# Resolve any $HOME references in CSS paths from theme.env
gtk_css="${GTK_CSS:-}"
gtk_css="${gtk_css/\$HOME/$HOME}"
thunar_css="${THUNAR_CSS:-}"
thunar_css="${thunar_css/\$HOME/$HOME}"

# Symlink the theme's GTK CSS overlay, or create an empty file if none is defined
if [[ -n "$gtk_css" && -f "$gtk_css" ]]; then
  ln -sf "$gtk_css" "$HOME/.config/gtk-3.0/current/gtk.css"
  echo "OK: GTK overlay -> $gtk_css"
else
  : > "$HOME/.config/gtk-3.0/current/gtk.css"
  echo "OK: GTK overlay -> (empty)"
fi

# Symlink the theme's Thunar CSS override, or create an empty file if none is defined
if [[ -n "$thunar_css" && -f "$thunar_css" ]]; then
  ln -sf "$thunar_css" "$HOME/.config/gtk-3.0/current/thunar.css"
  echo "OK: Thunar CSS -> $thunar_css"
else
  : > "$HOME/.config/gtk-3.0/current/thunar.css"
  echo "OK: Thunar CSS -> (empty)"
fi

# ---- GTK4 settings.ini
# Write a fresh GTK4 settings file (same structure as GTK3 but for GTK4 apps)
mkdir -p "$HOME/.config/gtk-4.0/current"

cat > "$HOME/.config/gtk-4.0/settings.ini" <<EOF
[Settings]
gtk-theme-name=${GTK_THEME:-}
gtk-icon-theme-name=${ICON_THEME:-}
gtk-font-name=${GTK_FONT:-Sans 10}
gtk-cursor-theme-name=${CURSOR_THEME:-default}
gtk-application-prefer-dark-theme=1
EOF

echo "OK: gtk-4.0/settings.ini updated"

# ---- GTK4 CSS router
# Write a GTK4 master CSS that imports the theme's GTK4 overlay from "current/"
cat > "$HOME/.config/gtk-4.0/gtk.css" <<'EOF'
/* Auto-generated by apply-theme.sh (GTK4 router) */
@import url("current/gtk4.css");
EOF

# Resolve $HOME references and symlink the GTK4 overlay, or create an empty file
gtk4_css="${GTK4_CSS:-}"
gtk4_css="${gtk4_css/\$HOME/$HOME}"

if [[ -n "$gtk4_css" && -f "$gtk4_css" ]]; then
  ln -sf "$gtk4_css" "$HOME/.config/gtk-4.0/current/gtk4.css"
  echo "OK: GTK4 overlay -> $gtk4_css"
else
  : > "$HOME/.config/gtk-4.0/current/gtk4.css"
  echo "OK: GTK4 overlay -> (empty)"
fi

# ---- Thunar
# Restart Thunar so it picks up the new GTK theme immediately.
# If it's not running, the new settings.ini will take effect on next launch.
if pgrep -x thunar >/dev/null 2>&1; then
  pkill -x thunar 2>/dev/null || true
  sleep 0.8
  thunar --daemon >/dev/null 2>&1 &
  echo "OK: thunar restarted"
else
  echo "OK: thunar not running, settings.ini will apply on next launch"
fi

# ---- Wallpaper
# Find a wallpaper image matching the theme name (any common image extension) and apply it via feh
wallpaper="$(find "$WALLPAPERS" -maxdepth 1 -iname "$THEME.*" \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | head -n 1 || true)"
[[ -n "${wallpaper:-}" ]] && feh --bg-scale "$wallpaper" || true

# ---- EWW sidebar state
# Check if the EWW sidebar widget is currently open so we can reopen it after restart
sidebar_was_open=false
if "$EWW_BIN" -c "$EWW_CONFIG" active-windows 2>/dev/null | grep -q '^sidebar'; then
  sidebar_was_open=true
  echo "INFO: sidebar was open, will reopen after restart"
fi

# Symlink the EWW CSS and yuck theme files for this theme into the "current" slots
THEME_CSS="$EWW_CONFIG/themes/$THEME.css"
THEME_YUCK="$EWW_CONFIG/yuck-themes/$THEME.yuck"

if [[ -f "$THEME_CSS" ]]; then
  ln -sf "$THEME_CSS" "$EWW_CONFIG/themes/current.css"
  echo "OK: EWW CSS -> $THEME_CSS"
else
  warn "EWW CSS theme not found: $THEME_CSS"
fi

if [[ -f "$THEME_YUCK" ]]; then
  ln -sf "$THEME_YUCK" "$EWW_CONFIG/generated/current-theme.yuck"
  echo "OK: EWW yuck -> $THEME_YUCK"
else
  warn "EWW yuck theme not found: $THEME_YUCK"
fi

# Restart the EWW daemon to apply the new theme, then reopen the sidebar if it was open
"$EWW_BIN" -c "$EWW_CONFIG" kill 2>/dev/null || true
sleep 0.3
"$EWW_BIN" -c "$EWW_CONFIG" daemon
sleep 0.4
[[ "$sidebar_was_open" == true ]] && "$EWW_BIN" -c "$EWW_CONFIG" open sidebar 2>/dev/null || true

# ---- Dunst
# Generate a dunstrc (notification daemon config) from a template, substituting
# color variables from theme.env (uses defaults if variables are not defined)
DUNST_TEMPLATE="$HOME/.config/dunst/dunst.conf"
DUNST_OUTPUT="$HOME/.config/dunst/dunstrc"

if [[ -f "$DUNST_TEMPLATE" ]]; then
  sed \
    -e "s|{{DUNST_BG}}|${DUNST_BG:-#282a36}|g" \
    -e "s|{{DUNST_FG}}|${DUNST_FG:-#f8f8f2}|g" \
    -e "s|{{DUNST_FRAME}}|${DUNST_FRAME:-#bd93f9}|g" \
    -e "s|{{DUNST_LOW_BG}}|${DUNST_LOW_BG:-#21222c}|g" \
    -e "s|{{DUNST_LOW_FG}}|${DUNST_LOW_FG:-#6272a4}|g" \
    -e "s|{{DUNST_LOW_FRAME}}|${DUNST_LOW_FRAME:-#8be9fd}|g" \
    -e "s|{{DUNST_CRITICAL_BG}}|${DUNST_CRITICAL_BG:-#ff5555}|g" \
    -e "s|{{DUNST_CRITICAL_FG}}|${DUNST_CRITICAL_FG:-#f8f8f2}|g" \
    -e "s|{{DUNST_CRITICAL_FRAME}}|${DUNST_CRITICAL_FRAME:-#ff79c6}|g" \
    -e "s|{{DUNST_FONT}}|${DUNST_FONT:-JetBrainsMono Nerd Font 10}|g" \
    -e "s|{{ICON_THEME}}|${ICON_THEME:-Papirus}|g" \
    "$DUNST_TEMPLATE" > "$DUNST_OUTPUT"

  echo "OK: dunstrc generated from template"

  # Restart dunst so it immediately picks up the new colors
  pkill -x dunst 2>/dev/null || true
  (dunst >/dev/null 2>&1 &)
  echo "OK: dunst restarted"
else
  warn "dunst template not found: $DUNST_TEMPLATE"
fi

# ---- Lock colors
# Write the i3lock color variables to a temp env file so the lock screen
# script can source it each time the screen is locked
cat > /tmp/i3lock-theme.env <<LOCKENV
LOCK_RING="${LOCK_RING:-bd93f9ff}"
LOCK_RING_VER="${LOCK_RING_VER:-8be9fdff}"
LOCK_RING_WRONG="${LOCK_RING_WRONG:-ff5555ff}"
LOCK_KEYHL="${LOCK_KEYHL:-f8f8f2ff}"
LOCK_BSHL="${LOCK_BSHL:-ff5555ff}"
LOCK_INSIDE="${LOCK_INSIDE:-00000000}"
LOCK_TIME_COLOR="${LOCK_TIME_COLOR:-f8f8f2ff}"
LOCK_DATE_COLOR="${LOCK_DATE_COLOR:-bd93f9ff}"
LOCK_VERIF_COLOR="${LOCK_VERIF_COLOR:-8be9fdff}"
LOCK_WRONG_COLOR="${LOCK_WRONG_COLOR:-ff5555ff}"
LOCK_BG="${LOCK_BG:-1e1f29}"
LOCK_SEPARATOR="${LOCK_SEPARATOR:-00000000}"
LOCK_LINE="${LOCK_LINE:-00000000}"
LOCK_LAYOUT_COLOR="${LOCK_LAYOUT_COLOR:-f8f8f2ff}"
LOCKENV

echo "OK: lock theme written to /tmp/i3lock-theme.env"

# ---- Save last theme
# Persist the theme name to a file so other scripts can know which theme was last applied
mkdir -p "$I3_THEMES"
echo "$THEME" > "$I3_THEMES/.last-theme"

# ---- Polybar restart
# Kill polybar and wait for it to fully exit before relaunching with the new theme
pkill -x polybar 2>/dev/null || true
while pgrep -x polybar >/dev/null; do sleep 0.1; done
rm -rf /tmp/polybar-lock
"$HOME/.config/polybar/launch.sh"

# ---- Starship theme switch
#
# DESIGN:
#   ~/.config/starship/themes/<theme>.toml  — per-theme configs
#   ~/.config/starship/current.toml         — symlink, updated on every switch
#   ~/.config/starship/env                  — sourced by ~/.zshrc at shell start
#                                             AND re-sourced live via TRAPUSR2
#
# We NEVER read the ambient $STARSHIP_CONFIG here. If we did, the symlink would
# just point back at whatever was already loaded and the theme would never change.
#
# To override the config path for a specific theme, set in that theme.env:
#   STARSHIP_CONFIG_OVERRIDE="/absolute/path/to/custom.toml"
# Do NOT use STARSHIP_CONFIG= in theme.env — it pollutes the environment and
# breaks the resolution logic above.
#
# Required in ~/.zshrc:
#   [[ -f "$HOME/.config/starship/env" ]] && source "$HOME/.config/starship/env"
#   TRAPUSR2() {
#     [[ -f "$HOME/.config/starship/env" ]] && source "$HOME/.config/starship/env"
#     zle reset-prompt 2>/dev/null || true
#   }

_starship_link="$HOME/.config/starship/current.toml"
_starship_env="$HOME/.config/starship/env"
_starship_cfg=""

# 1. Explicit per-theme override (STARSHIP_CONFIG_OVERRIDE in theme.env)
_override="${STARSHIP_CONFIG_OVERRIDE:-}"
_override="${_override/\$HOME/$HOME}"
if [[ -n "$_override" && -f "$_override" ]]; then
  _starship_cfg="$_override"
fi

# 2. Conventional per-theme path: ~/.config/starship/themes/<theme>.toml
if [[ -z "$_starship_cfg" ]]; then
  _candidate="$HOME/.config/starship/themes/$THEME.toml"
  [[ -f "$_candidate" ]] && _starship_cfg="$_candidate"
fi

# 3. Update symlink and env file
# If a config was found, point the symlink and env file at it;
# otherwise remove the symlink and unset STARSHIP_CONFIG to use starship's default
if [[ -n "$_starship_cfg" ]]; then
  ln -sf "$_starship_cfg" "$_starship_link"
  printf 'export STARSHIP_CONFIG="%s"\n' "$_starship_link" > "$_starship_env"
  echo "OK: starship -> $_starship_cfg"
else
  rm -f "$_starship_link"
  printf 'unset STARSHIP_CONFIG\n' > "$_starship_env"
  warn "no starship config for theme '$THEME' — fell back to starship default"
fi

# 4. Signal interactive non-login zsh terminals to reload via TRAPUSR2.
#
# WHY USR2 and not USR1:
#   USR1 causes zsh to fully re-exec itself. On login shells (argv[0] == "-zsh",
#   set by the kernel for TTY login sessions) this re-sources .zprofile/.zlogin,
#   which on most i3 setups re-launches startx or the display manager, putting
#   you in a login loop. USR2 is unassigned in zsh by default — safe to trap.
#
# SAFETY FILTERS — a PID is skipped if ANY condition is true:
#   • argv[0] starts with "-"      → login shell (kernel dash prefix), SKIP
#   • stdin fd is not a pts/tty    → pipe, subshell, daemon, SKIP
#   • stdin fd is our own tty      → don't signal the shell running this script
#   • /proc/$pid/cmdline missing   → dead/zombie process, SKIP

_my_tty="$(tty 2>/dev/null || true)"
_signaled=0

# Iterate over all zsh processes owned by this user and send USR2 to eligible ones
while IFS= read -r _pid; do
  [[ ! -r "/proc/$_pid/cmdline" ]] && continue

  _argv0="$(tr '\0' '\n' < "/proc/$_pid/cmdline" 2>/dev/null | head -n1 || true)"
  [[ "$_argv0" == -* ]] && continue   # login shell — kernel sets argv[0] to "-zsh"

  _tty="$(readlink -f "/proc/$_pid/fd/0" 2>/dev/null || true)"
  [[ -z "$_tty" ]] && continue
  [[ "$_tty" != /dev/pts/* && "$_tty" != /dev/tty* ]] && continue
  [[ "$_tty" == "$_my_tty" ]] && continue

  kill -USR2 "$_pid" 2>/dev/null || true
  echo "OK: USR2 -> pid=$_pid tty=$_tty"
  (( _signaled++ )) || true
done < <(pgrep -u "$(id -u)" -a 2>/dev/null | awk '/zsh/{print $1}' || true)
# pgrep -a is broader than pgrep -x: matches /bin/zsh, zsh, any cmdline with zsh

[[ "$_signaled" -eq 0 ]] && warn "no interactive zsh terminals found to signal (prompt will update on next new terminal)"

# Clean up all temporary variables used by the starship section
unset _starship_cfg _starship_link _starship_env _override _candidate
unset _my_tty _pid _argv0 _tty _signaled

# ---- Keep a stable pointer
# Re-affirm current.env at the end of the script in case anything above overwrote it
ln -sf "$THEME_ENV" "$I3_THEMES/current.env"
echo "OK: current.env -> $THEME_ENV"

# ---- Firefox Color theme sync
# If Firefox is running, open the matching Firefox Color theme URL in a new tab.
# Each named theme has a pre-built Firefox Color URL hardcoded below.
# Unknown themes are silently ignored (the * catch-all does nothing).
if command -v firefox >/dev/null 2>&1 && pgrep -x firefox >/dev/null 2>&1; then
  case "$THEME" in
    crimson)
      firefox --new-tab "https://color.firefox.com/?theme=XQAAAAIlAQAAAAAAAABBqYhm849SCia2CaaEGccwS-xMDPry_tqG6RbU7WTa5kPfqTomdcXV_tidEimRijn8Exg-a28ymwTp1RBuAQ2ROFMEjNuB2PkMqr1-xYUyfTx1Sdc9SEF1l0skkDYnwnHubNK_3hyQkYsVk_O7QrcAVTmtrz-DK3zg0lLAwuXHo8lW4LXQuOyDdV0CCIyi136jvshujL8TZDWNUS4eRnMn5TV6G95CwgD_VfOT-UjfYM3gFKb1-0DQf_6asqA" >/dev/null 2>&1 || true ;;
    brs)
      firefox --new-tab "https://color.firefox.com/?theme=XQAAAAIWAQAAAAAAAABBqYhm849SCia2CaaEGccwS-xMDPryROyHJagcfUBxAFBZz9tIJuNAJPA8jD27U6M-dXP4eg0aRw4Z_4Vp_AJW1y-DLhq4vH1cmXgF3BjA5eK85L5Jj2VHTaJX_n1h14qXWnQf5mejk1Gjmdz72BTirCg6FRKS4rjkOCuqefXHFDeoOWTgwowZXl3igV1fyvWzSqVIz4E9brtsntn5WV67yP__2a6AAA" >/dev/null 2>&1 || true ;;
    blue-yellow)
      firefox --new-tab "https://color.firefox.com/?theme=XQAAAAInAQAAAAAAAABBqYhm849SCia2CaaEGccwS-xMDPr0NLovL_vK2ZZN4vJyCB6sDY7NbbS7dCK95jr8fGsINzBaKLpVix2b7A5BQNdcT9EvHFZE4crlayoKI4wrXw3Dt32OqSsL3eq9CNJDen9yPXGN6RqOgCir78OfIbqPdP5w2AXR2TMO5GiT5D35wCsROH5TKjTO-rvuLJb2HA_LgswuqJn_w5O-HhCW9gYOhDsU7NLU6KnT-TRiv_6YjmQ" >/dev/null 2>&1 || true ;;
    dracula)
      firefox --new-tab "https://color.firefox.com/?theme=XQAAAAIYAQAAAAAAAABBqYhm849SCia2CaaEGccwS-xMDPr5iE6kjVUHIsGRvs0-q94VqJzDm3b6lMz-u5p-MmVLmkkIw60ZKbiPMYV2Mc50Wj4gKE18Wg3dHMrF5eZ9Njif4fmLWMjDY8n5HQRTFZc9CfKARue6H9E2V0TLvuFk57De_pIoCNcxJlzYK_ovf713RyzTCOSgaSeaCg3fwhmSYB5coKP9yyBqgD__et7AAA" >/dev/null 2>&1 || true ;;
    nord)
      firefox --new-tab "https://color.firefox.com/?theme=XQAAAAIZAQAAAAAAAABBqYhm849SCia2CaaEGccwS-xMDPr6_CqlFI4MnOwqZESgRUapmIlv5Q6tD8LGCwbxceMVH3u1BHna4uX0Fm5cJ6Kj0D0g7ZLz1f3QRxvXCffezPWxbTObAZwUseUlENv_JwsHm554lzIl2CCZ5Y1tKFe33fNrdH56XOzSuDjJMPB7_M8Si4G48VxbIs44htu2rw7HRvpZxQb86ZRZ9cX5f_9urCAA" >/dev/null 2>&1 || true ;;
    sakura-hunter)
      firefox --new-tab "https://color.firefox.com/?theme=XQAAAAIbAQAAAAAAAABBqYhm849SCia2CaaEGccwS-xMDPr2JIiHJqG2wwUG6Gh_mMt995UumRWttFy6QE2-wtB-rFf5U9VcToR9azgvnrAMWRcFmbmBONK33cj8xFyFra4GnINYzVTplm5C2EMLa2OQMpdMhrMkjyrGkKCqr0XcpUkCJ9thz4J7TpjcYavixmP3-SG64iHVe2gYYX6iI3wyT_wkggYMYffNaxUFoN__FnaXAA" >/dev/null 2>&1 || true ;;
    arch-rain)
      firefox --new-tab "https://color.firefox.com/?theme=XQAAAAIWAQAAAAAAAABBqYhm849SCia2CaaEGccwS-xMDPr07qaH_GaEiQNXswAFlQ3E_J3K72bAqyziM49R5hKbh2-rIbwQqUW2asyz5QAqMjuTXIg7CQ-mX87RlHsBW_ROoivqxo4nQoeOO7WFOCrAYx4ed3AKFMnpVaPlVsZa8gOOc7WdSTFpuDaoBStu3HZRdUwG-ulADsW9eQXMxB3ko_yy27NB1wdC5CIG8TrDQPP_6op0AA" >/dev/null 2>&1 || true ;;
    chill)
      firefox --new-tab "https://color.firefox.com/?theme=XQAAAAIQAQAAAAAAAABBqYhm849SCia2CaaEGccwS-xMDPrywOCHM5bOVwiKMBs0vZSwj6ZMh9rjHTEex_GVbco5Ww4Ik0-NyiFfIIs9kP17ueFrsaYWMbVs_BDrKiYVTKpqciRXBDkfqQ2qdKUAqPGgkGiDXclNbOVBIFsP5SvuBAMsBvZ6lFQSwTr86bde9jRb6-Nb_xKGKlYmlUDB40pMbSC_ZTdUR8tDjONnFn3UEHN__MxjQA" >/dev/null 2>&1 || true ;;
    devilman)
      firefox --new-tab "https://color.firefox.com/?theme=XQAAAAISAQAAAAAAAABBqYhm849SCia2CaaEGccwS-xMDPryguaGXiXB0qPHxXg2OurCpFHR5ZJw4khIrt83EO6LTedc1QLoi6JI2ATM3IESOMFYMFdm-gc6N9MG6A9vAJsjdW1hd3bBqlDBgCV-PXQPsrp7hme4NvFgnCI9pnLRW9qiP6Gw4wL7z8g20Lg4-SVwlmUqO4PU8ZddBNaVhUO8dBjGlf_4y9iA" >/dev/null 2>&1 || true ;;
    n7-day)
      firefox --new-tab "https://color.firefox.com/?theme=XQAAAAIUAQAAAAAAAABBqYhm849SCia2CaaEGccwS-xMDPry_tqG6RbU-RVlAFBZz9tIJuLFd92Q9yVvAldYMomrDO1_QEcp188Ngy_raeb3bpMhgCVOhuGU96d3SnzbXKbVqIyLlYWiJAk2M3RcB5SUVrdbcsivShiV09z46T1R7wWFUoZ-jd6WT9qoheaw3XH7yIw0bXvaaj920FQl8Za27_PQPi0C3GGgx6XWi99v9Mm1IhmgDkN5L_8EF0UA" >/dev/null 2>&1 || true ;;
    chill)
      firefox --new-tab "https://color.firefox.com/?theme=XQAAAAIQAQAAAAAAAABBqYhm849SCia2CaaEGccwS-xMDPrywOCHM5bOVwiKMBs0vZSwj6ZMh9rjHTEex_GVbco5Ww4Ik0-NyiFfIIs9kP17ueFrsaYWMbVs_BDrKiYVTKpqciRXBDkfqQ2qdKUAqPGgkGiDXclNbOVBIFsP5SvuBAMsBvZ6lFQSwTr86bde9jRb6-Nb_xKGKlYmlUDB40pMbSC_ZTdUR8tDjONnFn3UEHN__MxjQA" >/dev/null 2>&1 || true ;;
    neon-violet)
      firefox --new-tab "https://color.firefox.com/?theme=XQAAAAITAQAAAAAAAABBqYhm849SCia2CaaEGccwS-xMDPr3mIJF_BUyqmgkVlEob_WwPrCiWpH65OSaN-D5-O1nJR_Mzubv8Yur0J0LlbpjlyoFe-JX7PKD6vM4xqzSL3qDQZZZhAKCWiz2ddJ98IVRMZVuvqEZnY5OBM11leLCl1QzSzApPFJATC-0Xht-HA_yaN4CEy9RjTOYpB9GZjY5OrGMu3rf_3UgAAA" >/dev/null 2>&1 || true ;;
    celty)
      firefox --new-tab "https://color.firefox.com/?theme=XQAAAAIaAQAAAAAAAABBqYhm849SCia2CaaEGccwS-xMDPsqr3XFMtPpGefRVMi2PRQ3yeaX3TzodlBrW0B0t-13YNPRUCuTbqWmgH9As3uqyFXD5k_5f1_gadVCm6RzFwTGYulwDnM4IxXSWmj3Ah_-fNZkYbWEkQ53_VAQFI_EMAiPKSGT9PSacstzjCXm2FoPUPHfm6uw3vshERT8_9OX-b9zC9CoKay_-vkZl4A" >/dev/null 2>&1 || true ;;
    ena)
      firefox --new-tab "https://color.firefox.com/?theme=XQAAAAIkAQAAAAAAAABBqYhm849SCia2CaaEGccwS-xMDPsqr9AxKPUMxcmoB7LW1GpMaNnbCrCktA8RrZobn_6M6RW0STWi1BSx2TJjJhbRo1oiohtYmcNG-igiHSmNdxSFW9QYVZfcX65m1gRpesoc1hHTOf_80_c2IgW9AGWG5ef4b8zy99lECwFgXb6AuITmreQieD339GV30napKhTpyLUY6jujy7kLzyOgLLdZWhzx59Tnz7Pr-PGb5DoRfLXaH4ztn_8yhvwA" >/dev/null 2>&1 || true ;;      
    project-hail-mary)
      firefox --new-tab "https://color.firefox.com/?theme=XQAAAAIYAQAAAAAAAABBqYhm849SCia2CaaEGccwS-xMDPr1qJSIjIs4XM2yxy5PGDukvAxjomGV--xbP0eBdyjkbOedcKOcCGDaYBiCGzc07vfOYmSaFa-zm3Rq2WeykCJmtksMGWE67DYjllFE_7JK1vUeO82sRz4ryMgcFlNLG1YAA6TyZ8qThBO_u4K_eZ4Nqw_mMUZhnuI86NDC-WAf4hB3hFX2I7Vv849A0G5Hb7TfH3zibBmYEp__y_T4AA" >/dev/null 2>&1 || true ;;
    digital-circus)
      firefox --new-tab "https://color.firefox.com/?theme=XQAAAAITAQAAAAAAAABBqYhm849SCia2CaaEGccwS-xMDPr9496kKmmfgFBHYuVo1x2rpxSRyzVQW3mlqzFGMKzW2EIwAaP3LoDY0FrUkjXKLGXgFmLPFmSCIzNU8-IYDRHOMtk-9rK4c6oGrmlhmhWiQMmzSRxPj6i_K70FLZx5FAX9VVorW-LV-Bdy06n1pdDvvdnlnkwmGn9Kl63qXGDFSCSpbVTLLYzZXokszO7Q5Rb_952MBA" >/dev/null 2>&1 || true ;;        
    evangelion)
      firefox --new-tab "https://color.firefox.com/?theme=XQAAAAIRAQAAAAAAAABBqYhm849SCia2CaaEGccwS-xMDPsQa-oj-MQ-9W1cbcr6-JOAoSyfwYxEexyMkXRXmY41M9zFrFlxmc-Zf7xYwtwQY5jzM-qWqb401N1hJSwssPUVqKVhO_Vl11il4zG1lp-1Gv6r0aPmlMHp2hHfmBKI1frQBGS5UvU6ZXkn5wCD-4MRxhPrIRThs9apL5pRgi5kFJ5BBMINX_1jFYY" >/dev/null 2>&1 || true ;;        
    msi-white)
      firefox --new-tab "https://color.firefox.com/?theme=XQAAAAIbAQAAAAAAAABBqYhm849SCia2CaaEGccwS-xMDPsqu7TqWr6m1TfMHqvlJQCFCPXMmdabxhSg4I5hF9BEQZVRGtA2fQcdol5zvm6VSBgihD5dtL75sthqFNXvIJF8B3XkFBOWKOrTdivWrSyZZepyrZrqygiej5eNT1L8nA9aRe-1bj28BwMtgMqMMFX_PVpOjRpJXednHEQpwhFwBZI81QsTN1rcYDI2b9p8BLX_xK4AAA" >/dev/null 2>&1 || true ;;        
 
    *)
      # No Firefox Color URL defined for this theme — do nothing
      :
      ;;
  esac
fi

# ---- Geany colorscheme
# Only restarts Geany if there are no unsaved buffers.
# Geany marks unsaved documents with a leading "*" in the window title,
# e.g. "* myfile.py - Geany". We detect this via xdotool.
# If unsaved files are present (or xdotool is missing), we write the new
# scheme config but leave Geany running — colors apply on next launch.
if [[ -x "$HOME/.config/i3/geany-scheme.sh" ]]; then
  if pgrep -x geany >/dev/null 2>&1; then
    _geany_has_unsaved=false

    if command -v xdotool >/dev/null 2>&1; then
      # Check each Geany window title for a leading "*" indicating unsaved changes
      while IFS= read -r _wintitle; do
        if [[ "$_wintitle" == \** ]]; then
          _geany_has_unsaved=true
          break
        fi
      done < <(xdotool search --class geany getwindowname %@ 2>/dev/null || true)
    else
      # xdotool unavailable — can't safely check for unsaved files, so skip restart
      warn "xdotool not found — cannot check Geany for unsaved files; skipping restart to be safe"
      _geany_has_unsaved=true
    fi

    if [[ "$_geany_has_unsaved" == true ]]; then
      # Write the new scheme config but don't restart — user has unsaved work
      "$HOME/.config/i3/geany-scheme.sh" --from-current-env \
        && echo "OK: Geany scheme written (unsaved files present — skipping restart; colors apply on next launch)" \
        || warn "Geany scheme write failed"
    else
      # No unsaved files — write the scheme and restart Geany to apply immediately
      "$HOME/.config/i3/geany-scheme.sh" --from-current-env --restart \
        && echo "OK: Geany scheme applied and restarted" \
        || warn "Geany scheme switch failed"
    fi

    unset _geany_has_unsaved _wintitle
  else
    # Geany is not running — just write the scheme; it will apply on next launch
    "$HOME/.config/i3/geany-scheme.sh" --from-current-env \
      && echo "OK: Geany scheme written (will apply on next launch)" \
      || warn "Geany scheme write failed"
  fi
else
  warn "geany-scheme.sh not found or not executable"
fi
