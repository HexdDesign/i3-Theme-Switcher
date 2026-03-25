#!/usr/bin/env bash
# Hack-style center hub: apps + toggles + media controls
# Outputs polybar clickable areas (%{A:cmd:}...%{A})

# --- helpers ---
wifi_iface="$(nmcli -t -f DEVICE,TYPE,STATE dev status | awk -F: '$2=="wifi" {print $1; exit}')"
wifi_state="$(nmcli -t -f WIFI g 2>/dev/null | head -n1)"
ssid="$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2; exit}')"

bt_power="$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered/ {print $2; exit}')"
bt_icon="󰂯"
if [[ "$bt_power" == "yes" ]]; then bt_icon="󰂰"; fi

# wifi icon
wifi_icon="󰤭"
if [[ "$wifi_state" == "enabled" ]]; then
  if [[ -n "$ssid" ]]; then wifi_icon="󰤨"; else wifi_icon="󰤩"; fi
fi

# player status
pstatus="$(playerctl status 2>/dev/null)"
if [[ "$pstatus" == "Playing" ]]; then play_icon="󰏦"; else play_icon="󰐊"; fi

# --- commands ---
rofi_apps='/home/dizzy/.local/bin/rofi-apps'
open_steam='gtk-launch steam'
open_browser='xdg-open https://duckduckgo.com'
open_files='thunar'

toggle_wifi='nmcli r wifi off || nmcli r wifi on'
wifi_menu='~/.config/rofi/scripts/network-menu.sh'

toggle_bt='bluetoothctl power off || bluetoothctl power on'
bt_menu='~/.config/rofi/scripts/bluetooth-menu.sh'

prev_track='playerctl previous'
toggle_play='playerctl play-pause'
next_track='playerctl next'

# --- output ---
# spacing that matches Hack vibe
sp="  "
dot="·"

printf "%s" \
"%{A:$open_discord:}󰙯%{A} ${dot}${sp}"\
"%{A:$open_steam:}󰓓%{A} ${dot}${sp}"\
"%{A:$open_browser:}󰖟%{A} ${dot}${sp}"\
"%{A:$open_files:}󰉋%{A} ${dot}${sp}"\
"%{A:$rofi_apps:}󰍜%{A} ${dot}${sp}"\
"%{A:$wifi_menu:}%{A3:$toggle_wifi:}$wifi_icon%{A}%{A} ${dot}${sp}"\
"%{A:$bt_menu:}%{A3:$toggle_bt:}$bt_icon%{A}%{A} ${dot}${sp}"\
"%{A:$prev_track:}󰒮%{A} ${sp}"\
"%{A:$toggle_play:}$play_icon%{A} ${sp}"\
"%{A:$next_track:}󰒭%{A}"
