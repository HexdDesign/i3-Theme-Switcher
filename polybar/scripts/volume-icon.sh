#!/usr/bin/env bash
set -euo pipefail

# Outputs ONLY an icon (no scale/bar)
# Muted: 󰝟   Low: 󰕿   Med: 󰖀   High: 󰕾

mute="$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}')"
vol="$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | awk -F'/' 'NR==1{gsub(/ /,"",$2); gsub(/%/,"",$2); print $2}')"

if [[ -z "${vol:-}" ]]; then
  echo "󰕾"
  exit 0
fi

if [[ "${mute:-no}" == "yes" ]]; then
  echo "󰝟"
  exit 0
fi

# bucket volume
if (( vol <= 30 )); then
  echo "󰕿"
elif (( vol <= 70 )); then
  echo "󰖀"
else
  echo "󰕾"
fi
