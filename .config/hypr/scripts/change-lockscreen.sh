#!/usr/bin/env bash

# Close wofi if it's already open
pkill -x wofi

# Define paths
SKIN_DIR="$HOME/.config/hypr/hyprlock/skins"
MAIN_HYPRLOCK="$HOME/.config/hypr/hyprlock.conf"

notify-send -a "Hyprlock" -h string:x-canonical-private-synchronous:hyprlock "Hyprlock" "Select a lockscreen skin."

# Get list of skins (files ending in .conf)
CHOICE=$(ls "$SKIN_DIR" | grep '\.conf$' | wofi --dmenu --prompt "Select Hyprlock Skin")

if [ -n "$CHOICE" ]; then
    # Define the full path for the selected skin
    SELECTED_SKIN_PATH="$SKIN_DIR/$CHOICE"

    # Update hyprlock.conf to source the new skin
    # This overwrites the file with a single source line pointing to the selection
    echo "source = $SELECTED_SKIN_PATH" > "$MAIN_HYPRLOCK"

    notify-send -a "Hyprlock" -h string:x-canonical-private-synchronous:hyprlock -i preferences-desktop-theme "Hyprlock" "Skin changed to: ${CHOICE%.conf}"
fi
