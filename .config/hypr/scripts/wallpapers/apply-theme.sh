#!/bin/bash

THUMB_CACHE="$HOME/.cache/wallpaper-thumbs"
STATE_FILE="$HOME/.cache/theme_mode"
colors="$HOME/.cache/wal/colors-waybar.css"

img_path="${1:-$(cat "$HOME/.cache/wal/wal")}"
current_theme="${2:-$(cat "$STATE_FILE")}"

FILENAME=$(basename "$img_path")
THUMB_PATH="$THUMB_CACHE/${FILENAME}.jpg"

if [ -f "$THUMB_PATH" ]; then
    TARGET_IMG="$THUMB_PATH"
else
    TARGET_IMG="$img_path"
fi

if command -v wallust >/dev/null 2>&1; then
    echo "Updating system theme using: $(basename "$TARGET_IMG")"

	sed -i '/^@define-color text/d' "$colors"
	sed -i '/^@define-color text-invert/d' "$colors"
	if [ "$current_theme" = "Dark" ]; then
		wal -i "$img_path" --backend haishoku -n -q || \
		wal -i "$img_path" --backend colorthief -n -q || \
		wal -i "$img_path" -n -q # Final fallback to default backend
		echo "@define-color text #F5F5F5;" >> $colors
		echo "@define-color text-invert #121212;" >> $colors	
	else
		wal -l -i "$img_path" --backend haishoku -n -q || \
		wal -l -i "$img_path" --backend colorthief -n -q || \
		wal -l -i "$img_path" -n -q # Final fallback to default backend
		echo "@define-color text-invert #F5F5F5;" >> $colors	
		echo "@define-color text #121212;" >> $colors
	fi
    killall waybar && sleep 0.05
    systemctl --user restart waybar &
    swaync-client -rs
fi
