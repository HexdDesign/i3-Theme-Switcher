#!/bin/bash
set -euo pipefail
THEME="${1:?usage: $0 <theme>}"

EWW_BIN="/usr/bin/eww"
EWW_CFG="$HOME/.config/eww"

# Ensure generated/ directory exists
mkdir -p "$EWW_CFG/generated" "$EWW_CFG/themes"

ln -sf "$EWW_CFG/themes/$THEME.css"        "$EWW_CFG/themes/current.css"
ln -sf "$EWW_CFG/yuck-themes/$THEME.yuck"  "$EWW_CFG/generated/current-theme.yuck"

"$EWW_BIN" -c "$EWW_CFG" kill 2>/dev/null || true
sleep 0.5
"$EWW_BIN" -c "$EWW_CFG" daemon
sleep 0.6
"$EWW_BIN" -c "$EWW_CFG" open sidebar || true
