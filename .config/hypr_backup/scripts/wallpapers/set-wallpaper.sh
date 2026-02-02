#!/bin/bash
set -eu

# Папка с обоями
WALL_DIR="$HOME/.config/wallpapers"

# Проверяем, что папка существует
if [ ! -d "$WALL_DIR" ]; then
    echo "Папка с обоями не найдена: $WALL_DIR"
    exit 1
fi

# Формируем список файлов (только имена)
FILE_LIST=$(find "$WALL_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" \) -printf "%f\n")

# Открываем wofi меню
SELECTED_FILE=$(echo "$FILE_LIST" | wofi --dmenu --prompt "Select wallpaper")

# Если пользователь отменил выбор
[ -z "$SELECTED_FILE" ] && exit 1

# Полный путь к выбранному файлу
WALL="$WALL_DIR/$SELECTED_FILE"

echo "Setting wallpaper: $SELECTED_FILE"

# Устанавливаем обои через hyprpaper
hyprctl hyprpaper unload all
hyprctl hyprpaper preload "$WALL"
hyprctl hyprpaper wallpaper "eDP-1, $WALL"
hyprctl hyprpaper wallpaper "DP-1, $WALL"
echo "Wallpaper set successfully"

# Применяем pywal
if command -v wal >/dev/null 2>&1; then
    echo "Applying pywal colors..."
    wal -i "$WALL"
    echo "Pywal applied successfully"
    "$HOME/.config/mako/update-colors.sh"
else
    echo "Pywal not installed, skipping"
fi

