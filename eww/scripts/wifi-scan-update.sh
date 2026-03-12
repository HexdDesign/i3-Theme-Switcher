#!/usr/bin/env bash
# Update the wifi-results variable in Eww
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIFI_LIST="$("$SCRIPT_DIR/wifi-list.sh")"
eww update wifi-results="$WIFI_LIST"
