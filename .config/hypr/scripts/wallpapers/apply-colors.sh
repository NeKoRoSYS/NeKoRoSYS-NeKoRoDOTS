#!/bin/bash

THUMB_CACHE="$HOME/.cache/wallpaper-thumbs"
STATE_FILE="$HOME/.cache/theme_mode"
WAYBAR_MODE_FILE="$HOME/.cache/.waybar_mode"
waybar_colors="$HOME/.cache/wallust/colors-waybar.css"
rofi_colors="$HOME/.cache/wallust/colors-rofi.rasi"

MANAGEMENT_MODE=$(cat "$WAYBAR_MODE_FILE" 2>/dev/null || echo "static")

img_path="${1:-$(cat "$HOME/.cache/wallust/wal")}"
current_theme="${2:-$(cat "$STATE_FILE")}"

FILENAME=$(basename "$img_path")
THUMB_PATH="$THUMB_CACHE/${FILENAME}.jpg"

if [ -f "$THUMB_PATH" ]; then
    TARGET_IMG="$THUMB_PATH"
else
    TARGET_IMG="$img_path"
fi

PARAMS="$TARGET_IMG -q -C"

if command -v wallust >/dev/null 2>&1; then
    echo "Updating system theme using: $(basename "$TARGET_IMG")"
	systemctl --user stop navbar.service navbar-watcher.service navbar-hover.service

	if [ "$current_theme" = "Dark" ]; then
		wallust run "$TARGET_IMG" -q -C ~/.config/wallust/wallust-dark.toml || wallust run $TARGET_IMG -q -C ~/.config/wallust/wallust-dark.toml -b full
		printf "@define-color text #F5F5F5;\n@define-color text-invert #121212;\n" >> "$waybar_colors"
		echo "* { text: #F5F5F5; text-invert: #121212; }" >> "$rofi_colors"
	else
		wallust run "$TARGET_IMG" -q -C ~/.config/wallust/wallust-light.toml || wallust run $TARGET_IMG -q -C ~/.config/wallust/wallust-light.toml -b full
		printf "@define-color text-invert #F5F5F5;\n@define-color text #121212;\n" >> "$waybar_colors"
		echo "* { text: #121212; text-invert: #F5F5F5; }" >> "$rofi_colors"
	fi

	mv ~/.cache/wallust/colors-hyprland-raw.conf ~/.cache/wallust/colors-hyprland.conf

	swaync-client -rs

	case "$MANAGEMENT_MODE" in
	"static")
		systemctl --user restart navbar.service &
		;;
	"hover")
		systemctl --user restart navbar-hover.service &
		;;
	*)
		systemctl --user restart navbar-watcher.service &
		;;
	esac
fi
