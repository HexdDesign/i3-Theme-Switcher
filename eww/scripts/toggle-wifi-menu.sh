#!/bin/bash
TARGET="wifi-menu"

if eww active-windows | grep -q "$TARGET"; then
  eww close "$TARGET"
else
  # Close other menus first, silently
  eww close bluetooth-menu 2>/dev/null
  eww close brightness-control 2>/dev/null
  eww close volume-control 2>/dev/null
  eww open "$TARGET"
fi
