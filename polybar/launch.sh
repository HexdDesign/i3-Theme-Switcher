#!/bin/bash

# Atomic lockfile using mkdir
if ! mkdir /tmp/polybar-lock 2>/dev/null; then
    exit 0
fi
trap 'rm -rf /tmp/polybar-lock' EXIT

killall -q polybar
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.2; done

export MONITOR="${MONITOR:-eDP1}"
polybar top &
polybar bottom &
