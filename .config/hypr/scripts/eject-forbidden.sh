#!/bin/bash
# Define your forbidden workspace IDs here
FORBIDDEN=("1" "3")

socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
    # Listen for when a window is opened or moved to a workspace
    if [[ $line == openwindow* ]] || [[ $line == movewindow* ]]; then
        # Get the current window's workspace ID
        WS_ID=$(hyprctl activewindow -j | jq -r '.workspace.id')
        
        # Check if the ID is in the forbidden list
        for i in "${FORBIDDEN[@]}"; do
            if [[ "$WS_ID" == "$i" ]]; then
                # Move window to the next relative workspace silently
                hyprctl dispatch movetoworkspacesilent r+1
                break
            fi
        done
    fi
done
