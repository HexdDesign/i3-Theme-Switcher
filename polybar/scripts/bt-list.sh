#!/usr/bin/env bash
set -euo pipefail

bluetoothctl power on >/dev/null 2>&1 || true
(bluetoothctl --timeout 6 scan on >/dev/null 2>&1 &) || true

mapfile -t dev_lines < <(bluetoothctl devices 2>/dev/null || true)

if [[ ${#dev_lines[@]} -eq 0 ]]; then
  cat <<'EOF'
(box :orientation "v" :space-evenly false :spacing 4
  (label :class "bt-item" :text "No devices found")
  (label :class "bt-item" :text "Put device in pairing mode and scan again"))
EOF
  exit 0
fi

escape_eww() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  echo "$s"
}

# connected MACs (authoritative)
declare -A connected_now=()
while IFS= read -r line; do
  mac="$(awk '{print $2}' <<<"$line" || true)"
  [[ -n "${mac:-}" ]] && connected_now["$mac"]=1
done < <(bluetoothctl devices Connected 2>/dev/null || true)

declare -a device_list=()

for line in "${dev_lines[@]}"; do
  mac="$(awk '{print $2}' <<<"$line")"
  name="$(cut -d' ' -f3- <<<"$line")"
  [[ -z "${mac:-}" || -z "${name:-}" ]] && continue

  info="$(bluetoothctl info "$mac" 2>/dev/null || true)"

  paired=0
  connected=0
  if [[ -n "$info" ]]; then
    grep -q "^Paired: yes" <<<"$info" && paired=1 || true
    grep -q "^Connected: yes" <<<"$info" && connected=1 || true
  fi
  [[ -n "${connected_now[$mac]:-}" ]] && connected=1

  device_list+=("$connected|$paired|$mac|$name")
done

mapfile -t sorted_devices < <(printf '%s\n' "${device_list[@]}" | sort -t'|' -k1,1rn -k2,2rn -k4)

printf '(box :orientation "v" :space-evenly false :spacing 4\n'

for entry in "${sorted_devices[@]}"; do
  IFS='|' read -r connected paired mac name <<<"$entry"
  esc_name="$(escape_eww "$name")"

  icon="󰂯"
  class="bt-item"
  status=""

  if [[ "$connected" == "1" ]]; then
    class="bt-item bt-connected"
    status="✓"
    onclick="bash -c \\\"bluetoothctl disconnect $mac; sleep 0.15; ~/.config/eww/scripts/bt-scan-update.sh\\\""
  elif [[ "$paired" == "1" ]]; then
    status=""  # clean look
    onclick="bash -c \\\"bluetoothctl connect $mac; sleep 0.15; ~/.config/eww/scripts/bt-scan-update.sh\\\""
  else
    icon="󰂲"
    status="PAIR"
    onclick="bash -c \\\"bluetoothctl power on; bluetoothctl pairable on; bluetoothctl agent on; bluetoothctl default-agent; \
bluetoothctl pair $mac; bluetoothctl trust $mac; bluetoothctl connect $mac; sleep 0.15; ~/.config/eww/scripts/bt-scan-update.sh\\\""
  fi

  printf '  (button :class "%s" :onclick "%s"\n' "$class" "$onclick"
  printf '    (box :class "row" :orientation "h" :hexpand true :spacing 8\n'
  printf '      (label :class "row-name" :xalign 0 :hexpand true :truncate true :text "%s %s")\n' "$icon" "$esc_name"
  printf '      (label :class "row-status" :xalign 1 :text "%s")))\n' "$status"
done

printf ')\n'
