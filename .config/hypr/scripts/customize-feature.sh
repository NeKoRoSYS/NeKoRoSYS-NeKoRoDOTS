#!/usr/bin/env bash

pkill -x wofi

FEATURE=$1
MODE=$2

HYPR="$HOME/.config/hypr/configs/windowrules.conf"

case $FEATURE in
    lockscreen)
        SKIN_DIR="$HOME/.config/hypr/hyprlock/skins"
        MAIN="$HOME/.config/hypr/hyprlock.conf"
        
        makenotif customize preferences-desktop-theme Hyprlock "Select a lockscreen layout." true
        
        CHOICE=$(ls "$SKIN_DIR" | grep '\.conf$' | wofi --dmenu --prompt "Select Hyprlock Layout")

        if [ -n "$CHOICE" ]; then
            echo "source = $SKIN_DIR/$CHOICE" > "$MAIN"
            makenotif customize preferences-desktop-theme Hyprlock "Layout changed to: ${CHOICE%.conf}" true
        fi
        ;;
        
    wallpaper)
        SCRIPT_DIR="$HOME/.config/hypr/scripts/wallpapers"
        if [ "$MODE" == "random" ]; then
            "$SCRIPT_DIR/set-random.sh" &
        else
            "$SCRIPT_DIR/set-wallpaper.sh" &
            makenotif customize folder-pictures Wallpaper "Select a new background." true
        fi
        ;;

    wofi|panel|waybar)
        case $FEATURE in
            wofi)
                NAME="Wofi"
                ICON="preferences-desktop-theme"
                MSG="Select a Wofi skin."
                DIR="$HOME/.config/wofi/skins"
                CONFIG="$HOME/.config/wofi/config.json"
                STYLE="$HOME/.config/wofi/style.css"
                ;;
            panel)
                NAME="SwayNC"
                ICON="preferences-desktop-theme"
                MSG="Select a SwayNC style."
                DIR="$HOME/.config/swaync/skins"
                CONFIG="$HOME/.config/swaync/config.json"
                STYLE="$HOME/.config/swaync/style.css"
                ;;
            waybar)
                NAME="Waybar"
                ICON="preferences-desktop-theme"
                MSG="Select a waybar skin."
                DIR="$HOME/.config/waybar/skins"
                CONFIG="$HOME/.config/waybar/config.jsonc"
                STYLE="$HOME/.config/waybar/style.css"
                ;;
        esac

        makenotif customize "$ICON" "$NAME" "$MSG" true

        CHOICE=$(ls "$DIR" | wofi --dmenu --prompt "Select $NAME Skin")

        if [ -n "$CHOICE" ]; then
            PATH_SKIN="$DIR/$CHOICE"

            echo "@import \"$PATH_SKIN/style.css\";" > "$STYLE"

            sed -i "\|^source = $DIR/|d" "$HYPR"
            echo "source = $PATH_SKIN/layerrule.conf" >> "$HYPR"

            case $FEATURE in
                wofi)
                    cp "$PATH_SKIN/config" "$CONFIG"
                    ;;
                panel)
                    cp "$PATH_SKIN/config.json" "$CONFIG"
                    swaync-client -R
                    swaync-client -rs
                    ;;
                waybar)
                    echo "{ \"include\": [ \"$PATH_SKIN/layout.jsonc\" ] }" > "$CONFIG"
                    killall waybar && sleep 0.05
                    systemctl --user restart waybar &
                    ;;
            esac

            makenotif customize "$ICON" "$NAME" "Skin changed to: $CHOICE" true
        fi
        ;;
esac
