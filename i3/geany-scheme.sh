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

# ---- Prepare geany.conf
# Create the config directory and file if they don't exist yet
mkdir -p "$(dirname "$GEANY_CONF")"
[[ -f "$GEANY_CONF" ]] || : >"$GEANY_CONF"

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

    # If [geany] section didn't exist at all, prepend it
    # (cheap check: if we never entered it AND never wrote to it)
    # We can't prepend in END with awk easily, so rely on your file already having [geany].
  }
' "$GEANY_CONF" > "$tmp"

# Atomically replace the original config with the patched version
mv -f "$tmp" "$GEANY_CONF"
echo "OK: Wrote Geany scheme: $scheme -> $GEANY_CONF"

# ---- Optional Geany restart
if [[ "$restart" == true ]]; then
  if pgrep -x geany >/dev/null 2>&1; then
    # Kill the running instance, then relaunch detached from this script's session
    pkill -x geany 2>/dev/null || true
    setsid -f geany >/dev/null 2>&1 || true
    echo "OK: Geany restarted"
  else
    echo "NOTE: Geany not running; start it to see the change."
  fi
else
  echo "NOTE: Restart Geany to guarantee the scheme reloads."
fi
