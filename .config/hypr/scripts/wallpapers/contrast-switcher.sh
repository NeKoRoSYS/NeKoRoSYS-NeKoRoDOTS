#!/bin/bash

STATE_FILE="$HOME/.cache/theme_mode"

if [ ! -f "$STATE_FILE" ]; then
    echo "Dark" > "$STATE_FILE"
fi

CURRENT_MODE=$(cat "$STATE_FILE" 2>/dev/null || echo "Dark")
NEW_MODE=$([[ "$CURRENT_MODE" == "Dark" ]] && echo "Light" || echo "Dark")
echo "$NEW_MODE" > "$STATE_FILE"

bash ~/.config/hypr/scripts/wallpapers/apply-colors.sh "" "$NEW_MODE" >/dev/null
