#!/bin/bash

# Listen to workspace changes
handle() {
  case $1 in
    workspace*)
      # Find all pids of windows NOT on the current workspace
      # We use hyprctl to get the active workspace ID
      active_ws=$(hyprctl activeworkspace -j | jq '.id')

      # Get all client PIDs and their workspace IDs
      hyprctl clients -j | jq -r '.[] | "\(.pid) \(.workspace.id)"' | while read -r pid ws; do
        if [ "$ws" != "$active_ws" ]; then
          # Lower priority for background apps
          renice -n 19 -p "$pid" > /dev/null 2>&1
        else
          # Restore priority for active apps
          renice -n 0 -p "$pid" > /dev/null 2>&1
        fi
      done
      ;;
  esac
}

# Pipe the hyprland event stream into the handle function
socat -U - UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done
