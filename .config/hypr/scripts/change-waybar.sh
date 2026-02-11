#!/usr/bin/env bash

# Close wofi if it's already open
pkill -x wofi

# Define main entry-point paths
SKIN_DIR="$HOME/.config/waybar/skins"
MAIN_CONFIG="$HOME/.config/waybar/config.jsonc"
MAIN_STYLE="$HOME/.config/waybar/style.css"

makenotif waybar preferences-desktop-theme Waybar "Select a waybar skin." true

# Get list of skins
CHOICE=$(ls "$SKIN_DIR" | wofi --dmenu --prompt "Select Waybar Skin")

if [ -n "$CHOICE" ]; then
    # Define paths for the selected skin's components
    SELECTED_LAYOUT="$SKIN_DIR/$CHOICE/layout.jsonc"
    SELECTED_STYLE="$SKIN_DIR/$CHOICE/style.css"

    # 1. Update main config.jsonc to include the new layout
    echo "{ \"include\": [ \"$SELECTED_LAYOUT\" ] }" > "$MAIN_CONFIG"
    
    # 2. Update main style.css to import the new style
    echo "@import \"$SELECTED_STYLE\";" > "$MAIN_STYLE"

    # Restart Waybar to apply all changes (Layout, Styles, and Modules)
	killall waybar && sleep 0.05
	systemctl --user restart waybar &

    makenotif waybar preferences-desktop-theme Waybar "Skin changed to: $CHOICE" true
fi
