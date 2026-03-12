#!/usr/bin/env bash
# ~/.config/polybar/scripts/rofi-toggle.sh
# Status icon: shows ON when rofi is running, OFF otherwise.

# Uncomment the two commands below to hard code the app launcher 
# toggle button located on the bottom left to one color.
#COLOR="%{F#FFD36A}"
#RESET="%{F-}"

ICON_ON="${COLOR}󰪥${RESET}"
ICON_OFF="${COLOR}󰝦${RESET}"

state() {
  pgrep -x rofi >/dev/null && echo 1 || echo 0
}

prev="$(state)"
[[ "$prev" == "1" ]] && echo "$ICON_ON" || echo "$ICON_OFF"

while sleep 0.3; do
  cur="$(state)"
  if [[ "$cur" != "$prev" ]]; then
    [[ "$cur" == "1" ]] && echo "$ICON_ON" || echo "$ICON_OFF"
    prev="$cur"
  fi
done
