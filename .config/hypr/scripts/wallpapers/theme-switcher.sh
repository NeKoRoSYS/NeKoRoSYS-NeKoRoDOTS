#!/bin/bash

STATE_FILE="$HOME/.cache/theme_mode"

if [ ! -f "$STATE_FILE" ]; then
    echo "Dark" > "$STATE_FILE"
fi

CURRENT_MODE=$(cat "$STATE_FILE")

# Toggle the value in the file
if [ "$CURRENT_MODE" = "Dark" ]; then
    NEW_MODE="Light"
else
    NEW_MODE="Dark"
fi

echo "$NEW_MODE" > "$STATE_FILE"

# Pass the NEW_MODE to the apply script instead of the old CURRENT_MODE
bash ~/.config/hypr/scripts/wallpapers/apply-theme.sh "" "$NEW_MODE"
