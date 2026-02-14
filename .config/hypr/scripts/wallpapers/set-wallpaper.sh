#!/bin/bash
set -eu

# Directory setup
WALL_DIR="$HOME/.config/wallpapers"
THUMB_CACHE="$HOME/.cache/wofi-thumbs"
VIDEO_CACHE="$HOME/.cache/last_video"
SOCKET="/tmp/mpvsocket"

mkdir -p "$THUMB_CACHE"
[[ ! -d "$WALL_DIR" ]] && echo "Wallpapers not found: $WALL_DIR" && exit 1

gen_thumb() {
    local FILE_PATH="$1"
    local FILENAME=$(basename "$FILE_PATH")
    local EXT=$(echo "${FILENAME##*.}" | tr '[:upper:]' '[:lower:]')
    local OUT="$THUMB_CACHE/${FILENAME}.jpg"

    [ -f "$OUT" ] && return

    case "$EXT" in
        mp4|mkv|webm)
            ffmpeg -y -i "$FILE_PATH" -ss 00:00:02 -frames:v 1 -vf "scale=200:-1" "$OUT" > /dev/null 2>&1
            ;;
        png|jpg|jpeg)
            magick "$FILE_PATH" -thumbnail 200x "$OUT" > /dev/null 2>&1
            ;;
    esac
}

if [ -n "${1:-}" ]; then
    SELECTED_FILE=$(basename "$1")
else
    THUMB_CACHE="$HOME/.cache/wofi-thumbs"
    mkdir -p "$THUMB_CACHE"

    FILE_LIST=$(find "$WALL_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) | while read -r line; do
        FILENAME=$(basename "$line")
        EXT="${FILENAME##*.}"
        THUMB_PATH="$THUMB_CACHE/${FILENAME}.jpg"
        [ ! -f "$THUMB_PATH" ] && gen_thumb "$line" & 
        echo "img:$THUMB_PATH:text:$FILENAME"        
    done)

    RAW_SELECTION=$(echo "$FILE_LIST" | wofi --dmenu --allow-images --prompt "Select wallpaper")    
    SELECTED_FILE=$(echo "$RAW_SELECTION" | sed 's/^.*:text://')
fi

[ -z "$SELECTED_FILE" ] && exit 0

if [[ "$SELECTED_FILE" =~ ^http ]]; then
    URL="$SELECTED_FILE"
    CLEAN_NAME=$(echo "${URL##*/}" | cut -d? -f1)
    EXT=$(echo "${CLEAN_NAME##*.}" | tr '[:upper:]' '[:lower:]')
    DEST="$WALL_DIR/$CLEAN_NAME"

    case "$EXT" in
        png|jpg|jpeg|mp4|mkv|webm)
            echo "Supported media: $EXT. Downloading..."
            makenotif "Download" "folder-download" "Downloading" "$CLEAN_NAME" "false" "" "0"
            ;;
        *)
            makenotif "Download" "dialog-error" "Error" "Unsupported type: .$EXT" "false" "error-sound" ""
            exit 1
            ;;
    esac

    set +e
    curl -L --progress-bar -o "$DEST" "$URL" 2>&1 | \
    stdbuf -oL tr '\r' '\n' | \
    sed -un 's/.* \([0-9]\{1,3\}\)\.[0-9]%.*/\1/p' | \
    while read -r progress; do
        makenotif "Download" "folder-download" "Downloading" "$progress% completed." "true" "" "$progress"
    done
    
    DL_STATUS="${PIPESTATUS[0]}"
    set -e

    if [ "$DL_STATUS" -eq 0 ]; then
        SELECTED_FILE="$CLEAN_NAME"
        # --- NEW: Generate thumbnail for the fresh download immediately ---
        gen_thumb "$DEST"
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
        bash ~/.config/hypr/scripts/wallpapers/apply-theme.sh $TEMP_THUMB
        
        # Comprehensive mvpaper parameters:
        # -o passes mpv flags: 
        #   loop-file=inf (loop forever)
        #   --mute (no sound)
        #   --no-osc/--no-osd-bar (hide UI)
        #   --no-input-default-bindings (disable keyboard/mouse interaction)
        #   --hwdec=auto (hardware acceleration for lower CPU usage)
	export LIBVA_DRIVER_NAME=iHD
        __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia mpvpaper -o "--input-ipc-server=$SOCKET loop-file=inf --mute --no-osc --no-osd-bar --hwdec=nvdec --vo=gpu --gpu-context=wayland --no-input-default-bindings" '*' "$WALL" &
	mpvpaper-stop --socket-path "$SOCKET" --period 500 --fork &
        ;;
    
    png|jpg|jpeg)
        echo "Image detected: $SELECTED_FILE"
        cleanup_backgrounds

	rm -f "$VIDEO_CACHE"
        
        # SWWW image setting (supports transitions)
        swww img "$WALL"
                
        # Pywal with your specific backends        
        bash ~/.config/hypr/scripts/wallpapers/apply-theme.sh $WALL
        ;;
    *)
        echo "Unsupported format: $EXTENSION"
        exit 1
        ;;
esac

echo "Wallpaper update complete."
makenotif customize "folder-pictures" "Wallpaper" "Changed wallpaper to $SELECTED_FILE" "true" ""

