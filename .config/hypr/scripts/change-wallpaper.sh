#!/usr/bin/env bash

pkill -x rofi

MODE=$1
SCRIPT_DIR="$HOME/.config/hypr/scripts/wallpapers"

if [ "$MODE" == "random" ]; then
    "$SCRIPT_DIR/set-random.sh" &
else
    "$SCRIPT_DIR/set-wallpaper.sh" &
    makenotif wallpaper folder-pictures Wallpaper "Select a new background." true
fi
