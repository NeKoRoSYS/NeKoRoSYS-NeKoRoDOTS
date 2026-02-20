#!/bin/bash
set -eu

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
WALL_DIR="$HOME/.config/wallpapers"
THUMB_CACHE="$HOME/.cache/wallpaper-thumbs"
VIDEO_CACHE="$HOME/.cache/last_video"
SOCKET="/tmp/mpvsocket"

mkdir -p "$THUMB_CACHE"
[[ ! -d "$WALL_DIR" ]] && echo "Wallpapers not found: $WALL_DIR" && exit 1

gen_thumb() {
    local FILE_PATH="$1"
    local FILENAME=$(basename "$FILE_PATH")
    local OUT="$THUMB_CACHE/${FILENAME}.jpg"

    [ -f "$OUT" ] && return

    case "${FILENAME##*.}" in
        mp4|mkv|webm|MP4|MKV|WEBM)
            ffmpeg -y -discard nokey -i "$FILE_PATH" -ss 00:00:02 -frames:v 1 -vf "scale=200:-1" "$OUT" > /dev/null 2>&1
            ;;
        png|jpg|jpeg|PNG|JPG|JPEG)
            magick "$FILE_PATH" -thumbnail 200x "$OUT" > /dev/null 2>&1
            ;;
    esac
}

if [ -n "${1:-}" ]; then
    SELECTED_FILE="${1##*/}"
else
    shopt -s nocaseglob nullglob

    get_wallpapers() {
        for file in "$WALL_DIR"/*.{jpg,jpeg,png,mp4,mkv,webm}; do
            FILENAME="${file##*/}"
            THUMB_PATH="$THUMB_CACHE/${FILENAME}.jpg"
            
            if [[ ! -f "$THUMB_PATH" ]]; then
                gen_thumb "$file"
            fi
            
            echo -en "${FILENAME}\0icon\x1f${THUMB_PATH}\n"
        done
    }

    if [ -n "${1:-}" ]; then
        RAW_SELECTION="$1"
    else
        RAW_SELECTION=$(get_wallpapers | rofi -dmenu \
            -i \
            -p "Select Wallpaper" \-show-icons \
            -theme-str 'window { width: 800px; }' \
	    -theme-str 'listview { columns: 4; lines: 3; spacing: 15px; fixed-columns: true; flow: horizontal; }' \
            -theme-str 'element { orientation: vertical; padding: 10px; border-radius: 10px; }' \
            -theme-str 'element-icon { size: 120px; horizontal-align: 0.5; }' \
            -theme-str 'element-text { horizontal-align: 0.5; padding: 5px 0px 0px 0px; }');
    fi

    [ -z "$RAW_SELECTION" ] && exit 0

    if [[ -f "$RAW_SELECTION" ]]; then
        WALL="$RAW_SELECTION"
        SELECTED_FILE="${RAW_SELECTION##*/}"
    else
        SELECTED_FILE="${RAW_SELECTION##*/}"
        WALL="$WALL_DIR/$SELECTED_FILE"
    fi
    
    shopt -u nocaseglob nullglob
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

        TEMP_THUMB="/tmp/wall_thumb.jpg"
        ffmpeg -y -ss 00:00:05 -i "$WALL" -frames:v 1 -vf "scale=200:-1" "$TEMP_THUMB" > /dev/null 2>&1

        bash "$SCRIPT_DIR/apply-colors.sh" "$WALL"

        export LIBVA_DRIVER_NAME=iHD
        if lspci | grep -qi nvidia; then
            export __GLX_VENDOR_LIBRARY_NAME=nvidia
            HWDEC="nvdec"
        else
            HWDEC="auto"
        fi

        __NV_PRIME_RENDER_OFFLOAD=1 mpvpaper -o "--input-ipc-server=$SOCKET loop-file=inf --mute --no-osc --no-osd-bar --hwdec=$HWDEC --vo=gpu --gpu-context=wayland --no-input-default-bindings" '*' "$WALL" &
        mpvpaper-stop --socket-path "$SOCKET" --period 500 --fork &
        ;;

    png|jpg|jpeg)
        echo "Image detected: $SELECTED_FILE"
        cleanup_backgrounds

        rm -f "$VIDEO_CACHE"

        swww img "$WALL"

        bash "$SCRIPT_DIR/apply-colors.sh" "$WALL"
        ;;
    *)
        echo "Unsupported format: $EXTENSION"
        exit 1
        ;;
esac

echo "Wallpaper update complete."
echo "$WALL" > ~/.cache/wallust/wal
makenotif customize "folder-pictures" "Wallpaper" "Changed wallpaper to $SELECTED_FILE" "true" ""
