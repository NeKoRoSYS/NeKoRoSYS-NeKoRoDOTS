#!/usr/bin/env bash

# Kill any existing wofi immediately
pkill -x wofi

MODE=$1

# Map modes to commands and text
case $MODE in
    run)
        TITLE="Run Command"
        MSG="Type a command to execute."
        CMD="wofi --show run"
        ;;
    game)
        TITLE="Game Mode"
        MSG="Select an app with Gamemode."
        CMD="gamemoderun wofi --show drun"
        ;;
    drun)
        TITLE="Select App"
        MSG="Select an app to run."
        CMD="wofi --show drun"
        ;;
esac

# Launch the new wofi and the notification in parallel
$CMD & 
notify-send -a "Wofi" \
            -h string:x-canonical-private-synchronous:wofi-status \
            -i system-run \
            "$TITLE" "$MSG"
