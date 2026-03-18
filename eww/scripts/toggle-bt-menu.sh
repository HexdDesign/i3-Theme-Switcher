#!/usr/bin/env bash
set -euo pipefail
if eww active-windows | grep -qx "bluetooth-menu"; then
  eww close bluetooth-menu || true
else
  eww open bluetooth-menu
fi
