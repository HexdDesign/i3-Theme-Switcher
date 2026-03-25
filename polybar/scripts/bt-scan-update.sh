#!/usr/bin/env bash
# Update the bt_results variable in Eww
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BT_LIST="$("$SCRIPT_DIR/bt-list.sh")"
eww update bt_results="$BT_LIST"
