#!/usr/bin/env bash

# Close wofi if it's open (e.g. if the wallpaper script uses wofi to select)
pkill -x wofi

MODE=$1
SCRIPT_DIR="$HOME/.config/hypr/scripts/wallpapers"

if [ "$MODE" == "random" ]; then
    "$SCRIPT_DIR/set-random.sh" &
    notify-send -a "Wallpaper" -h string:x-canonical-private-synchronous:wallpaper -i image-jpeg "Wallpaper" "Randomized successfully."
else
    "$SCRIPT_DIR/set-wallpaper.sh" &
    notify-send -a "Wallpaper" -h string:x-canonical-private-synchronous:wallpaper -i folder-pictures "Wallpaper" "Select a new background."
fi
