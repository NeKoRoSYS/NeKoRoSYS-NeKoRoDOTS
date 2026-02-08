#!/bin/bash
set -eu

# Directory setup
WALL_DIR="$HOME/.config/wallpapers"
VIDEO_CACHE="$HOME/.cache/last_video"
SOCKET="/tmp/mpvsocket"

[[ ! -d "$WALL_DIR" ]] && echo "Wallpapers not found: $WALL_DIR" && exit 1

# List images and videos
FILE_LIST=$(find "$WALL_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) -printf "%f\n")

# Selection menu
SELECTED_FILE=$(echo "$FILE_LIST" | wofi --dmenu --prompt "Select background")
[ -z "$SELECTED_FILE" ] && exit 0

WALL="$WALL_DIR/$SELECTED_FILE"
EXTENSION="${SELECTED_FILE##*.}"

# Cleanup function to prevent overlapping wallpaper managers
cleanup_backgrounds() {
    pkill mpvpaper || true
    pkill -f mpvpaper-stop || true
    rm -f "$SOCKET" || true
    # We don't kill swww-daemon, but we might want to clear its state 
    # if mvpaper is going to cover the whole screen.
}

apply_theme() {
    local img_path="$1"
    if command -v wal >/dev/null 2>&1; then
        echo "Updating system theme..."
        wal -i "$img_path" --backend haishoku -n -q || wal -i "$img_path" --backend colorthief -n -q
        "$HOME/.config/mako/update-colors.sh"
    fi
}

case "$(echo "$EXTENSION" | tr '[:upper:]' '[:lower:]')" in
    mp4|mkv|webm)
        echo "Video detected: $SELECTED_FILE"
        cleanup_backgrounds

	echo "$WALL" > "$VIDEO_CACHE"

        # 1. Generate a temporary thumbnail for pywal
        TEMP_THUMB="/tmp/wall_thumb.jpg"
        # -ss 00:00:05: Seeks to 5 seconds (to avoid black intro frames)
        # -frames:v 1: Capture exactly one frame
        # -y: Overwrite the file if it exists
        ffmpeg -y -ss 00:00:05 -i "$WALL" -frames:v 1 "$TEMP_THUMB" > /dev/null 2>&1

        # 2. Apply pywal using the extracted frame
        apply_theme $TEMP_THUMB
        
        # Comprehensive mvpaper parameters:
        # -o passes mpv flags: 
        #   loop-file=inf (loop forever)
        #   --mute (no sound)
        #   --no-osc/--no-osd-bar (hide UI)
        #   --no-input-default-bindings (disable keyboard/mouse interaction)
        #   --hwdec=auto (hardware acceleration for lower CPU usage)
	export LIBVA_DRIVER_NAME=iHD
        __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia mpvpaper -o "--input-ipc-server=$SOCKET loop-file=inf --mute --no-osc --no-osd-bar --hwdec=nvdec --vo=gpu --gpu-context=wayland --no-input-default-bindings" '*' "$WALL" &
#        __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia mpvpaper -o "--input-ipc-server=$SOCKET loop-file=inf --mute --no-osc --no-osd-bar --hwdec=vaapi --vaapi-device=/dev/dri/renderD129 --gpu-context=wayland --no-input-default-bindings" '*' "$WALL" &
#        mpvpaper -o "loop-file=inf --mute --no-osc --no-osd-bar --hwdec=vaapi --vaapi-device=/dev/dri/renderD129 --gpu-context=wayland --no-input-default-bindings" '*' "$WALL" &
	mpvpaper-stop --socket-path "$SOCKET" --period 500 --fork &
        ;;
    
    png|jpg|jpeg)
        echo "Image detected: $SELECTED_FILE"
        cleanup_backgrounds

	rm -f "$VIDEO_CACHE"
        
        # SWWW image setting (supports transitions)
        swww img "$WALL"
                
        # Pywal with your specific backends        
	apply_theme $WALL

        ;;
    *)
        echo "Unsupported format: $EXTENSION"
        exit 1
        ;;
esac

echo "Wallpaper update complete."
