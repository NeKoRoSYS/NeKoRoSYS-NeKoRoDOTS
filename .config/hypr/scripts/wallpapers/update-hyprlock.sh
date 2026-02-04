#!/bin/bash

# Extract the current wallpaper path from swww
# This regex picks the absolute path for any image file listed in the query output
WALLPAPER=$(swww query | grep -oP '/.*\.(jpg|png|jpeg|webp)' | head -n 1)

# Path to your hyprlock config
CONF="$HOME/.config/hypr/hyprlock.conf"

# If a wallpaper is found, update the config file
if [ -n "$WALLPAPER" ]; then
    # This sed command targets the 'path =' line specifically inside the 'background {' block
    sed -i "/^background {/,/^}/{s|^[[:space:]]*path =.*|    path = $WALLPAPER|}" "$CONF"
fi
