#!/usr/bin/env bash

# Close wofi if it's open (e.g. if the wallpaper script uses wofi to select)
pkill -x wofi

MODE=$1
SCRIPT_DIR="$HOME/.config/hypr/scripts/wallpapers"

if [ "$MODE" == "random" ]; then
    "$SCRIPT_DIR/set-random.sh" &
    makenotif wallpaper image-jpeg Wallpaper "Randomized successfully." true
else
    "$SCRIPT_DIR/set-wallpaper.sh" &
    makenotif wallpaper folder-pictures Wallpaper "Select a new background." true
fi
