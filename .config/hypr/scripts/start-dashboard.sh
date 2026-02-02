#!/bin/bash

# 1. Kill existing instances to prevent duplicates
pkill btop
pkill tty-clock
pkill fastfetch

# 2. Launch apps with specific class names for Hyprland rules
# We use 'kitty --class' so we can target these specific windows
kitty --class dashboard-clock -e tty-clock -c -C 4 &
sleep 0.1
kitty --class dashboard-fetch -e zsh -c "fastfetch; zsh"
sleep 0.1
kitty --class dashboard-sys -e btop &

# 3. Optional: Open a file manager or music player
# dolphin &
