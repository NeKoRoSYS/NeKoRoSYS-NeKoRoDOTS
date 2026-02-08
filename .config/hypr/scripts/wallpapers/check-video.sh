#!/bin/bash
VIDEO_CACHE="$HOME/.cache/last_video"

if [[ -f "$VIDEO_CACHE" ]]; then
    WALL=$(cat "$VIDEO_CACHE")
    # Restore video with same 5s logic
    export LIBVA_DRIVER_NAME=iHD
    __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia mpvpaper -o "--input-ipc-server=$SOCKET loop-file=inf --mute --no-osc --no-osd-bar --hwdec=nvdec --vo=gpu --gpu-context=wayland --no-input-default-bindings" '*' "$WALL" &
#    mpvpaper -o "--input-ipc-server=/tmp/mpvsocket --loop-file=inf --mute --no-osc --no-osd-bar --hwdec=vaapi --vaapi-device=/dev/dri/renderD129 --gpu-context=wayland --no-input-default-bindings" '*' "$WALL" &
#    mpvpaper -o "--loop-file=inf --mute --no-osc --no-osd-bar --hwdec=vaapi --vaapi-device=/dev/dri/renderD129 --gpu-context=wayland --no-input-default-bindings" '*' "$WALL" &
    mpvpaper-stop --socket-path /tmp/mpvsocket --period 500 --fork &
    
    # Optional: re-apply theme on boot
    TEMP_THUMB="/tmp/wall_thumb.jpg"
    ffmpeg -y -ss 00:00:05 -i "$WALL" -frames:v 1 "$TEMP_THUMB" > /dev/null 2>&1
fi
