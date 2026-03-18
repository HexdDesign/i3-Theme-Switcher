#!/usr/bin/env bash
set -euo pipefail

win="${1:-}"
if [[ -z "$win" ]]; then
  echo "Usage: $0 <eww-window-id>" >&2
  exit 2
fi

# toggle only (no backdrops)
eww open --toggle "$win"
