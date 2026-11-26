#!/usr/bin/env bash

# Windows 11-style Emoji Picker using rofi-emoji
# Copies selected emoji directly to clipboard (Wayland).

ROFI_THEME="$HOME/.config/rofi/emoji.rasi"

# Toggle off if already open
if pgrep -x "rofi" >/dev/null; then
    pkill -x rofi
    exit 0
fi

# Run rofi and capture selected emoji on stdout
SELECTED=$(rofi \
    -modi emoji \
    -show emoji \
    -emoji-format "{emoji}" \
    -emoji-mode stdout \
    -theme "$ROFI_THEME")

# If user cancelled / pressed Escape, exit cleanly
[ -z "$SELECTED" ] && exit 0

# Strip trailing whitespace and take only the emoji character
EMOJI=$(printf "%s" "$SELECTED" | head -n 1 | tr -d '\n\r')
[ -z "$EMOJI" ] && exit 0

# Copy to Wayland clipboard
printf "%s" "$EMOJI" | wl-copy
