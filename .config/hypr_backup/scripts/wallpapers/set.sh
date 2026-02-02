#!/bin/bash
set -eu

WALL=$1
echo "setting $WALL as wallpaper"
hyprctl hyprpaper unload all
hyprctl hyprpaper preload "$WALL"
hyprctl hyprpaper wallpaper ", $WALL"
echo "set $WALL as wallpaper sucessfuly"



if command -v wal >/dev/null 2>&1; then
    echo "applying pywal colors..."
    wal -i "$WALL"
    echo "pywal applied successfully"
else
    echo "pywal not installed, skipping"
fi

