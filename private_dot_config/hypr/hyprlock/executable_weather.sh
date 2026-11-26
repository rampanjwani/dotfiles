#!/usr/bin/env bash

# Optional: set a specific city (e.g. "Mumbai") or leave empty for auto-detection
LOCATION=""

CACHE_FILE="/tmp/hyprlock_weather.txt"
CACHE_TIME=900 # 15 minutes

now=$(date +%s)
last_mod=0

if [ -f "$CACHE_FILE" ]; then
    last_mod=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
fi

if [ $((now - last_mod)) -gt $CACHE_TIME ] || [ ! -f "$CACHE_FILE" ]; then
    URL="wttr.in/${LOCATION}?format=%l:+%c+%C+%t"
    raw=$(curl -s --connect-timeout 4 "$URL" 2>/dev/null | tr -d '\n')
    if [ -n "$raw" ] && [[ ! "$raw" =~ "Unknown" ]] && [[ ! "$raw" =~ "html" ]] && [[ ! "$raw" =~ "<" ]]; then
        loc=$(echo "$raw" | cut -d: -f1 | cut -d, -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        details=$(echo "$raw" | cut -d: -f2- | sed -E 's/[[:space:]]+/ /g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [ -n "$loc" ] && [ -n "$details" ]; then
            echo "$loc: $details" > "$CACHE_FILE"
        else
            echo "$raw" > "$CACHE_FILE"
        fi
    fi
fi

if [ -f "$CACHE_FILE" ]; then
    cat "$CACHE_FILE"
fi
