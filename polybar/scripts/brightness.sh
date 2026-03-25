#!/usr/bin/env bash
# Polybar brightness module: icon + bar + percent
# Prefers brightnessctl, falls back to xbacklight

FILLED="██████████"
EMPTY="░░░░░░░░░░"

get_pct_brightnessctl() {
  local cur max
  cur="$(brightnessctl get 2>/dev/null)" || return 1
  max="$(brightnessctl max 2>/dev/null)" || return 1
  [[ -z "$cur" || -z "$max" || "$max" -eq 0 ]] && return 1
  echo $(( cur * 100 / max ))
}

get_pct_xbacklight() {
  local v
  v="$(xbacklight -get 2>/dev/null)" || return 1
  # round
  printf "%.0f\n" "$v"
}

get_pct_sysfs() {
  # Fallback to direct sysfs reading
  local backlight_dir brightness max_brightness
  if [[ ! -d /sys/class/backlight ]]; then
    return 1
  fi
  
  backlight_dir=$(ls /sys/class/backlight 2>/dev/null | head -n 1)
  [[ -z "$backlight_dir" ]] && return 1
  
  brightness=$(cat /sys/class/backlight/"$backlight_dir"/brightness 2>/dev/null) || return 1
  max_brightness=$(cat /sys/class/backlight/"$backlight_dir"/max_brightness 2>/dev/null) || return 1
  
  [[ -z "$brightness" || -z "$max_brightness" || "$max_brightness" -eq 0 ]] && return 1
  
  echo $(( brightness * 100 / max_brightness ))
}

pct=""

# Try brightnessctl first
if command -v brightnessctl >/dev/null 2>&1; then
  pct="$(get_pct_brightnessctl)" || pct=""
fi

# Try xbacklight if brightnessctl failed
if [[ -z "$pct" ]] && command -v xbacklight >/dev/null 2>&1; then
  pct="$(get_pct_xbacklight)" || pct=""
fi

# Try direct sysfs as last resort
if [[ -z "$pct" ]]; then
  pct="$(get_pct_sysfs)" || pct=""
fi

# If still nothing works, show error
if [[ -z "$pct" ]]; then
  echo "󰃟 --"
  exit 0
fi

# Clamp 0-100
(( pct < 0 )) && pct=0
(( pct > 100 )) && pct=100

# Calculate bar segments
filled=$(( pct / 10 ))
empty=$(( 10 - filled ))
bar="${FILLED:0:filled}${EMPTY:0:empty}"

# Icon ramp
if (( pct == 0 )); then
  icon="󰃞"
elif (( pct < 35 )); then
  icon="󰃟"
elif (( pct < 70 )); then
  icon="󰃠"
else
  icon="󰃡"
fi

printf "%s %s %3d%%" "$icon" "$bar" "$pct"
