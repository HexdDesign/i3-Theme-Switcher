#!/usr/bin/env bash
# geany-scheme.sh
# Updates the color scheme entries in Geany's config file (geany.conf).
# Can read the scheme name directly as an argument or pull it from the current theme's env file.
# Optionally restarts Geany afterward to apply the change immediately.
set -euo pipefail

# Path to Geany's main config file (respects XDG_CONFIG_HOME if set)
GEANY_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/geany/geany.conf"

# Directory containing all i3 theme subdirectories
THEMES_DIR="$HOME/.config/i3/themes"

# Symlink that always points to the currently active theme's env file
CURRENT_ENV="$THEMES_DIR/current.env"

# ---- Usage help text
usage() {
  cat <<'EOF'
Usage:
  geany-scheme.sh <SchemeFile.conf> [--restart]
  geany-scheme.sh --from-current-env [--restart]

Examples:
  geany-scheme.sh DEVILMAN.conf
  geany-scheme.sh --from-current-env
  geany-scheme.sh DEVILMAN.conf --restart
EOF
}

# ---- Argument parsing
restart=false        # whether to kill and relaunch Geany after writing the config
from_current=false   # whether to read the scheme name from current.env instead of argv
scheme=""            # the scheme filename to write into geany.conf

for arg in "$@"; do
  case "$arg" in
    --restart) restart=true ;;
    --from-current-env) from_current=true ;;
    -h|--help) usage; exit 0 ;;
    *)
      # First positional argument is the scheme name; error on any extra positional args
      if [[ -z "${scheme}" ]]; then
        scheme="$arg"
      else
        echo "ERROR: extra arg: $arg" >&2
        usage
        exit 2
      fi
      ;;
  esac
done

# ---- Resolve scheme name from current.env if --from-current-env was passed
if [[ "$from_current" == true ]]; then
  [[ -f "$CURRENT_ENV" ]] || { echo "ERROR: current.env not found: $CURRENT_ENV" >&2; exit 1; }
  # Load the active theme's variables (we need GEANY_SCHEME)
  # shellcheck disable=SC1090
  source "$CURRENT_ENV"
  scheme="${GEANY_SCHEME:-}"
fi

# Abort if we still have no scheme name after all resolution attempts
[[ -n "${scheme:-}" ]] || { echo "ERROR: No scheme provided." >&2; usage; exit 2; }

# ---- Verify the scheme file actually exists in Geany's colorschemes directory
COLORSCHEMES_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/geany/colorschemes"
if [[ ! -f "$COLORSCHEMES_DIR/$scheme" ]]; then
  echo "WARNING: Scheme file not found at $COLORSCHEMES_DIR/$scheme" >&2
  echo "         Geany will silently fall back to its default theme." >&2
  echo "         Available schemes:" >&2
  if [[ -d "$COLORSCHEMES_DIR" ]]; then
    ls "$COLORSCHEMES_DIR" >&2 || echo "         (directory is empty)" >&2
  else
    echo "         (directory does not exist: $COLORSCHEMES_DIR)" >&2
  fi
fi

# ---- FIX: Kill Geany BEFORE writing the config.
# Geany writes its config on exit and will overwrite any changes made while it is running.
geany_was_running=false
if pgrep -x geany >/dev/null 2>&1; then
  geany_was_running=true
  if [[ "$restart" == true ]]; then
    echo "INFO: Stopping Geany before patching config..."
    pkill -x geany 2>/dev/null || true
    # Wait up to 3 seconds for Geany to fully exit and flush its config
    for i in {1..6}; do
      sleep 0.5
      pgrep -x geany >/dev/null 2>&1 || break
    done
    # If still running, force-kill
    if pgrep -x geany >/dev/null 2>&1; then
      echo "INFO: Geany did not exit cleanly; force-killing..."
      pkill -9 -x geany 2>/dev/null || true
      sleep 0.5
    fi
  else
    echo "WARNING: Geany is currently running. It will overwrite your changes when it exits." >&2
    echo "         Use --restart to have this script handle it safely." >&2
  fi
fi

# ---- Prepare geany.conf
# Create the config directory and file if they don't exist yet
mkdir -p "$(dirname "$GEANY_CONF")"
[[ -f "$GEANY_CONF" ]] || : >"$GEANY_CONF"

# ---- FIX: Ensure [geany] and [editor] sections exist before patching.
# If either section is missing, awk can update keys within it but cannot create the section itself.
# We append any missing sections (with their required keys) before running awk.
if ! grep -q '^\[geany\]' "$GEANY_CONF"; then
  echo "INFO: [geany] section missing from geany.conf; adding it."
  printf '\n[geany]\ncolor_scheme=\n' >> "$GEANY_CONF"
fi
if ! grep -q '^\[editor\]' "$GEANY_CONF"; then
  echo "INFO: [editor] section missing from geany.conf; adding it."
  printf '\n[editor]\ncolor_scheme=\nuse_custom_colors=false\nuse_legacy_editor_colors=false\n' >> "$GEANY_CONF"
fi

# ---- Patch geany.conf with awk
# This awk script edits ONLY the relevant keys inside [geany] and [editor] sections,
# leaving all other sections and keys completely untouched.
#
# Keys managed in [geany]:
#   color_scheme=           — the active color scheme file
#
# Keys managed in [editor]:
#   color_scheme=           — same scheme reference for the editor component
#   use_custom_colors=      — forced to false so the scheme file takes full control
#   use_legacy_editor_colors= — forced to false for modern scheme compatibility
#
# If any of these keys are missing from their section, they are appended before
# the section ends (i.e. when the next section header is encountered, or at EOF).
tmp="$(mktemp)"
awk -v scheme="$scheme" '
  BEGIN {
    in_geany=0; in_editor=0;
    geany_written=0; editor_written=0;
    seen_geany_cs=0; seen_editor_cs=0;
    seen_uc=0; seen_ul=0;
  }

  # flush_missing_for_section: called whenever we are about to leave a section.
  # Appends any keys that were never encountered (and therefore never rewritten).
  function flush_missing_for_section() {
    if (in_geany && !seen_geany_cs) {
      print "color_scheme=" scheme
      geany_written=1
    }
    if (in_editor) {
      if (!seen_editor_cs) { print "color_scheme=" scheme; editor_written=1 }
      if (!seen_uc)        { print "use_custom_colors=false" }
      if (!seen_ul)        { print "use_legacy_editor_colors=false" }
    }
  }

  # Section header: flush missing keys for the section we are leaving,
  # then update tracking flags for the section we are entering
  /^\[[^]]+\]$/ {
    flush_missing_for_section()

    in_geany = ($0 == "[geany]")
    in_editor = ($0 == "[editor]")

    # reset per-section "seen"
    if (in_geany) {
      seen_geany_cs=0
    } else if (in_editor) {
      seen_editor_cs=0; seen_uc=0; seen_ul=0
    }

    print
    next
  }

  # Inside [geany]: replace color_scheme line with the new value; pass all other lines through
  in_geany {
    if ($0 ~ /^color_scheme=/) {
      if (!seen_geany_cs) { print "color_scheme=" scheme; seen_geany_cs=1 }
      next
    }
    print
    next
  }

  # Inside [editor]: replace color_scheme, use_custom_colors, and use_legacy_editor_colors;
  # pass all other lines through unchanged
  in_editor {
    if ($0 ~ /^color_scheme=/) {
      if (!seen_editor_cs) { print "color_scheme=" scheme; seen_editor_cs=1 }
      next
    }
    if ($0 ~ /^use_custom_colors=/) {
      if (!seen_uc) { print "use_custom_colors=false"; seen_uc=1 }
      next
    }
    if ($0 ~ /^use_legacy_editor_colors=/) {
      if (!seen_ul) { print "use_legacy_editor_colors=false"; seen_ul=1 }
      next
    }
    print
    next
  }

  # Outside any managed section: pass lines through unchanged
  { print }

  END {
    # Flush any missing keys if the file ended while still inside a managed section
    flush_missing_for_section()
  }
' "$GEANY_CONF" > "$tmp"

# Atomically replace the original config with the patched version
mv -f "$tmp" "$GEANY_CONF"
echo "OK: Wrote Geany scheme: $scheme -> $GEANY_CONF"

# ---- Optional Geany restart
if [[ "$restart" == true ]]; then
  if [[ "$geany_was_running" == true ]]; then
    setsid -f geany >/dev/null 2>&1 || true
    echo "OK: Geany restarted"
  else
    echo "NOTE: Geany was not running; start it to see the change."
  fi
else
  if [[ "$geany_was_running" == true ]]; then
    echo "NOTE: Geany was left stopped. Restart it manually to see the change."
    echo "      Or re-run with --restart to have this script handle it."
  else
    echo "NOTE: Start Geany to see the new scheme."
  fi
fi
