#!/usr/bin/env bash
set -euo pipefail

nmcli dev wifi rescan >/dev/null 2>&1 || true

mapfile -t lines < <(nmcli -t -f IN-USE,SSID,SIGNAL dev wifi 2>/dev/null | head -n 120)

declare -A best_sig active
for line in "${lines[@]}"; do
  IFS=':' read -r inuse ssid signal <<<"$line"
  [[ -z "${ssid}" || "${ssid}" == "--" ]] && continue
  [[ "${signal}" =~ ^[0-9]+$ ]] || continue

  if [[ -z "${best_sig[$ssid]+x}" || "${signal}" -gt "${best_sig[$ssid]}" ]]; then
    best_sig["$ssid"]="$signal"
  fi
  [[ "$inuse" == "*" ]] && active["$ssid"]=1
done

# nothing found
if [[ "${#best_sig[@]}" -eq 0 ]]; then
  echo '(label :class "wifi-item" :text "No networks found")'
  exit 0
fi

# sort: active first, then signal desc
mapfile -t sorted < <(
  for ssid in "${!best_sig[@]}"; do
    a="${active[$ssid]:-0}"
    s="${best_sig[$ssid]}"
    printf "%d\t%d\t%s\n" "$a" "$s" "$ssid"
  done | sort -t$'\t' -k1,1nr -k2,2nr | head -n 15
)

# Escape for Eww literal content (inside double quotes in the yuck file)
escape_eww() {
  # Escape backslashes first, then double quotes
  local str="$1"
  str="${str//\\/\\\\}"
  str="${str//\"/\\\"}"
  echo "$str"
}

# ---- print ONE root box ----
printf '(box :orientation "v" :space-evenly false :spacing 6\n'

for row in "${sorted[@]}"; do
  IFS=$'\t' read -r a s ssid <<<"$row"

  if   (( s > 75 )); then icon="󰤨"
  elif (( s > 50 )); then icon="󰤥"
  elif (( s > 25 )); then icon="󰤢"
  else                    icon="󰤟"
  fi

  # Escape the SSID for use in onclick command AND display
  esc_ssid="$(escape_eww "$ssid")"

  if [[ "$a" == "1" ]]; then
    # Connected network - just show notification
    printf '  (button :class "wifi-item wifi-connected" :onclick "notify-send WiFi \\"Already connected to %s\\"" "✓ %s %s %d%%")\n' \
      "$esc_ssid" "$icon" "$esc_ssid" "$s"
  else
    # Available network - connect on click
    printf '  (button :class "wifi-item" :onclick "bash -c \\"nmcli dev wifi connect '\''%s'\'' && notify-send WiFi '\''Connected to %s'\'' || notify-send WiFi '\''Failed to connect'\''\\"" "%s %s %d%%")\n' \
      "$ssid" "$ssid" "$icon" "$esc_ssid" "$s"
  fi
done

printf ')\n'
