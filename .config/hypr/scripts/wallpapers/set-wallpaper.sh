#!/bin/bash
set -eu

# Directory setup
WALL_DIR="$HOME/.config/wallpapers"
VIDEO_CACHE="$HOME/.cache/last_video"
SOCKET="/tmp/mpvsocket"

[[ ! -d "$WALL_DIR" ]] && echo "Wallpapers not found: $WALL_DIR" && exit 1

if [ -n "${1:-}" ]; then
    SELECTED_FILE=$(basename "$1")
else
    FILE_LIST=$(find "$WALL_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) -printf "%f\n")
    SELECTED_FILE=$(echo "$FILE_LIST" | wofi --dmenu --allow-images --prompt "Select background or paste link")
fi

[ -z "$SELECTED_FILE" ] && exit 0

if [[ "$SELECTED_FILE" =~ ^http ]]; then
    URL="$SELECTED_FILE"
    CLEAN_NAME=$(echo "${URL##*/}" | cut -d? -f1)
    # Force lowercase for reliable comparison
    EXT=$(echo "${CLEAN_NAME##*.}" | tr '[:upper:]' '[:lower:]')
    DEST="$WALL_DIR/$CLEAN_NAME"

    # 1. Supported File Type Check
    case "$EXT" in
        png|jpg|jpeg|mp4|mkv|webm)
            echo "Supported media: $EXT. Downloading..."
            makenotif "Download" "folder-download" "Downloading" "$CLEAN_NAME" "false" "" "0"
            ;;
        *)
            # Error notification for unsupported types
            makenotif "Download" "dialog-error" "Error" "Unsupported type: .$EXT" "false" "error-sound" ""
            exit 1
            ;;
    esac

    # 2. Stable Download Logic
    # We temporarily disable 'set -e' for the pipe to prevent the I/O error
    set +e
    curl -L --progress-bar -o "$DEST" "$URL" 2>&1 | \
    stdbuf -oL tr '\r' '\n' | \
    sed -un 's/.* \([0-9]\{1,3\}\)\.[0-9]%.*/\1/p' | \
    while read -r progress; do
        makenotif "Download" "folder-download" "Downloading" "$progress% completed." "true" "" "$progress"
    done
    
    # Capture the exit status of the FIRST command in the pipe (curl)
    DL_STATUS="${PIPESTATUS[0]}"
    set -e # Re-enable error safety

    if [ "$DL_STATUS" -eq 0 ]; then
        SELECTED_FILE="$CLEAN_NAME"
        makenotif "Download" "folder-download" "Download Complete" "$CLEAN_NAME" "true" "complete.oga" "100"
    else
        makenotif "Download" "dialog-error" "Download Failed" "Check your connection." "false" "error-sound" ""
        rm -f "$DEST"
        exit 1
    fi
fi


WALL="$WALL_DIR/$SELECTED_FILE"
EXTENSION="${SELECTED_FILE##*.}"

# Cleanup function to prevent overlapping wallpaper managers
cleanup_backgrounds() {
    set +e
    pkill mpvpaper || true
    pkill -f mpvpaper-stop || true
    rm -f "$SOCKET" || true
    set -e
}

apply_theme() {
    local img_path="$1"
    if command -v wal >/dev/null 2>&1; then
        echo "Updating system theme..."
	rm -f "$HOME/.cache/wal/schemes/*"
	wal -i "$img_path" --backend haishoku -n -q || \
        wal -i "$img_path" --backend colorthief -n -q || \
        wal -i "$img_path" -n -q # Final fallback to default backend
	killall waybar && sleep 0.05
	systemctl --user restart waybar &
        swaync-client -rs
        #"$HOME/.config/mako/update-colors.sh"
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
makenotif wallpaper "folder-pictures" "Wallpaper" "Changed wallpaper to $SELECTED_FILE" "true" ""
