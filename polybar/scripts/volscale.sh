#!/usr/bin/env bash
# Polybar volume "scale" — icon + bar + percent
# pactl (PipeWire-Pulse or PulseAudio)

# 10-step bar using blocks (much more readable than dashes)
FILLED="██████████"
EMPTY="░░░░░░░░░░"

# Read volume (first channel) and mute state
vol="$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | awk -F'/' 'NR==1{gsub(/ /,"",$2); gsub(/%/,"",$2); print $2}')"
mute="$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}')"

if [[ -z "$vol" ]]; then
  echo "󰕾 --"
  exit 0
fi

# Clamp 0–150 (pactl can go over 100)
(( vol < 0 )) && vol=0
(( vol > 150 )) && vol=150

# Use 0–100 for the bar fill amount
barvol=$vol
(( barvol > 100 )) && barvol=100

filled=$(( barvol / 10 ))
empty=$(( 10 - filled ))

bar="${FILLED:0:filled}${EMPTY:0:empty}"

# Icon ramp
if [[ "$mute" == "yes" || "$vol" -eq 0 ]]; then
  icon="󰖁"
elif (( vol < 35 )); then
  icon="󰕿"
elif (( vol < 70 )); then
  icon="󰖀"
else
  icon="󰕾"
fi

# Slight spacing for readability
printf "%s %s" "$icon" "$bar"


