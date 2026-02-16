#!/bin/bash
VIDEO_CACHE="$HOME/.cache/last_video"

if [[ -f "$VIDEO_CACHE" ]]; then
    WALL=$(cat "$VIDEO_CACHE")
    export LIBVA_DRIVER_NAME=iHD
    if lspci | grep -qi nvidia; then
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        HWDEC="nvdec"
    else
        HWDEC="auto"
    fi
    __NV_PRIME_RENDER_OFFLOAD=1 mpvpaper -o "--input-ipc-server=$SOCKET loop-file=inf --mute --no-osc --no-osd-bar --hwdec=$HWDEC --vo=gpu --gpu-context=wayland --no-input-default-bindings" '*' "$WALL" &
    mpvpaper-stop --socket-path /tmp/mpvsocket --period 500 --fork &
    TEMP_THUMB="/tmp/wall_thumb.jpg"
    ffmpeg -y -ss 00:00:05 -i "$WALL" -frames:v 1 "$TEMP_THUMB" > /dev/null 2>&1
fi
