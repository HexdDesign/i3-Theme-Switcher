#!/usr/bin/env bash
set -euo pipefail
if eww active-windows | grep -qx "brightness-control"; then
  eww close brightness-control || true
else
  eww open brightness-control
fi
