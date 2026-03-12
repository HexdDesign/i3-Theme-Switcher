#!/usr/bin/env bash
set -euo pipefail

# ======================
# CONFIG
# ======================
LAT="43.08"
LON="-71.08"

ENV_FILE="$HOME/.config/polybar/scripts/weather.env"
CACHE="/tmp/polybar_weather.json"
CACHE_TTL=240

TEXT_COLOR="#123d88"   # matches your bg

# ======================
# LOAD API KEY
# ======================
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

if [[ -z "${API_KEY:-}" ]]; then
  echo "󰔟 --° • --"
  exit 0
fi

# ======================
# FETCH (CACHED)
# ======================
now="$(date +%s)"
mtime=0
[[ -f "$CACHE" ]] && mtime="$(stat -c %Y "$CACHE" 2>/dev/null || echo 0)"

if (( now - mtime > CACHE_TTL )); then
  curl -fsS --max-time 4 \
    "https://api.openweathermap.org/data/2.5/weather?lat=$LAT&lon=$LON&appid=$API_KEY&units=imperial" \
    -o "$CACHE" 2>/dev/null || true
fi

# ======================
# VALIDATE
# ======================
if ! command -v jq >/dev/null 2>&1 || [[ ! -s "$CACHE" ]]; then
  echo "󰔟 --° • --"
  exit 0
fi

# ======================
# PARSE
# ======================
temp="$(jq -r '.main.temp // empty' "$CACHE")"
condition="$(jq -r '.weather[0].description // empty' "$CACHE")"

if [[ -z "$temp" || -z "$condition" ]]; then
  echo "󰔟 --° • --"
  exit 0
fi

temp="$(printf "%.0f" "$temp")"
condition="$(tr '[:upper:]' '[:lower:]' <<<"$condition")"

# ======================
# ICON MAP
# ======================
icon="☁️"
case "$condition" in
  *clear*)   icon="☀️" ;;
  *cloud*)   icon="☁️" ;;
  *rain*)    icon="🌧️" ;;
  *drizzle*) icon="🌧️" ;;
  *thunder*) icon="⛈️" ;;
  *snow*)    icon="❄️" ;;
  *mist*|*fog*|*haze*) icon="🌫️" ;;
esac


# ======================
# OUTPUT
# ======================
printf '%s %s°F • %s\n' "$icon" "$temp" "$condition"
