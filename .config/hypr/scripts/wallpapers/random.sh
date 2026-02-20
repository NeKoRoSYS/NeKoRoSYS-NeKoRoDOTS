#!/bin/bash

WALLPAPERS_DIR="$HOME/.config/wallpapers"
NEW_WALL=$(find $WALLPAPERS_DIR -type f | shuf -n 1)

echo $NEW_WALL
