#!/usr/bin/env bash

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

$CMD & 
makenotif wofi system-run "$TITLE" "$MSG" true
