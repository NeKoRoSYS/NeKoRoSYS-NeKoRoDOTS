#!/usr/bin/env bash

# Close wofi if it's already open
pkill -x wofi

# Define paths
SKIN_DIR="$HOME/.config/hypr/hyprlock/skins"
MAIN_HYPRLOCK="$HOME/.config/hypr/hyprlock.conf"

makenotif hyprlock preferences-desktop-theme Hyprlock "Select a lockscreen layout." true

# Get list of skins (files ending in .conf)
CHOICE=$(ls "$SKIN_DIR" | grep '\.conf$' | wofi --dmenu --prompt "Select Hyprlock Layout")

if [ -n "$CHOICE" ]; then
    SELECTED_SKIN_PATH="$SKIN_DIR/$CHOICE"
    echo "source = $SELECTED_SKIN_PATH" > "$MAIN_HYPRLOCK"

    makenotif hyprlock preferences-desktop-theme Hyprlock "Layout changed to: ${CHOICE%.conf}" true
fi
