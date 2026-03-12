#!/usr/bin/env bash
set -euo pipefail

EWW="/usr/bin/eww"
CFG="/home/dizzy/.config/eww"
WINDOW="${1:-sidebar}"

export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"

$EWW -c "$CFG" daemon >/dev/null 2>&1 || true
$EWW -c "$CFG" open --toggle "$WINDOW" >/dev/null 2>&1
