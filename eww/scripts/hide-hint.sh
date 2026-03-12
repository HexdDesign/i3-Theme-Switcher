#!/usr/bin/env bash
set -euo pipefail

# usage: hide-hint.sh bri_hint_show
VAR="${1:?missing var name}"

# flip to true immediately (caller sets it too; harmless)
eww update "${VAR}=true"

# hide after a short delay
(sleep 0.8; eww update "${VAR}=false") >/dev/null 2>&1 &
