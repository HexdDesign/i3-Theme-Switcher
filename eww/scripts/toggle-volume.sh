#!/usr/bin/env bash
set -euo pipefail
if eww active-windows | grep -qx "volume-control"; then
  eww close volume-control || true
else
  eww open volume-control
fi
