#!/usr/bin/env bash

if pgrep -x hyprshot > /dev/null || pgrep -x slurp > /dev/null; then
    killall -9 hyprshot slurp hyprpicker grim
    exit 0 # Stop script execution here
fi

MODE=$1


if [ "$MODE" == "region" ]; then
    hyprshot -m region --clipboard-only --freeze -s
else
    hyprshot -m $MODE --clipboard-only -s
fi

notify-send -a "Hyprshot" \
    -h string:x-canonical-private-synchronous:shot \
    -i screenshot \
    "Hyprshot" \
    "Captured $MODE to clipboard!"
