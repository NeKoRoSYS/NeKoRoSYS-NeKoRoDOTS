#!/bin/bash
set -eu

WALL=$1
echo "setting $WALL as wallpaper"
swww img "$WALL"
bash ~/.config/hypr/scripts/wallpapers/update-hyprlock.sh
echo "set $WALL as wallpaper sucessfuly"

if command -v wal >/dev/null 2>&1; then
    echo "applying pywal colors..."
    wal -i "$WALL" --b haishoku -n || wal -i "$WALL" --b colorthief -n
    echo "pywal applied successfully"
else
    echo "pywal not installed, skipping"
fi

