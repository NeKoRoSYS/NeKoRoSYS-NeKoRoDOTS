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
    SELECTED_FILE=$(basename "$1")
else
    find "$WALL_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) -print0 \
    | xargs -0 -P4 -n1 -I {} bash -c '
        FILE_PATH="$1"
        FILENAME=$(basename "$FILE_PATH")
        THUMB_CACHE="$2"
        OUT="$THUMB_CACHE/${FILENAME}.jpg"
        
        [ -f "$OUT" ] && exit 0
        
        case "${FILENAME##*.}" in
            mp4|mkv|webm|MP4|MKV|WEBM)
                ffmpeg -y -discard nokey -i "$FILE_PATH" -ss 00:00:02 -frames:v 1 -vf "scale=200:-1" "$OUT" > /dev/null 2>&1 || true
                ;;
            png|jpg|jpeg|PNG|JPG|JPEG)
                magick "$FILE_PATH" -thumbnail 200x "$OUT" > /dev/null 2>&1 || true
                ;;
        esac
    ' _ "{}" "$THUMB_CACHE" || true

    FILE_LIST=$(find "$WALL_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \) -printf "img:$THUMB_CACHE/%f.jpg:text:%f\n")

    if RAW_SELECTION=$(echo "$FILE_LIST" | wofi --dmenu --allow-images --prompt "Select wallpaper"); then
        SELECTED_FILE=$(echo "$RAW_SELECTION" | sed 's/^.*:text://')
    else
        exit 0
    fi
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

        bash "$SCRIPT_DIR/apply-theme.sh" "$WALL"

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

        bash "$SCRIPT_DIR/apply-theme.sh" "$WALL"
        ;;
    *)
        echo "Unsupported format: $EXTENSION"
        exit 1
        ;;
esac

echo "Wallpaper update complete."
echo "$WALL" > ~/.cache/wallust/wal
makenotif customize "folder-pictures" "Wallpaper" "Changed wallpaper to $SELECTED_FILE" "true" ""
