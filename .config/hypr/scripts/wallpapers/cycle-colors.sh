#!/bin/bash

WAYBAR_CONFIG="$HOME/.config/waybar/config.jsonc"
WAYBAR_LAYOUT=$(grep -oP '"include":\s*\[\s*"\K[^"]+' "$WAYBAR_CONFIG" | head -1)
SKIN_DIR=$(dirname "$WAYBAR_LAYOUT")
WAYBAR_STYLE="$HOME/${SKIN_DIR#~/}/style.css"

WOFI_STYLE="$HOME/.config/wofi/skins/legacy/style.css"
SWAYNC_STYLE="$HOME/.config/swaync/skins/legacy/style.css"

HYPRLOCK_MAIN="$HOME/.config/hypr/hyprlock.conf"
HYPRLOCK_SKIN=$(grep -oP "source = \K.*" "$HYPRLOCK_MAIN" | sed "s|~|$HOME|")

FILES=("$WAYBAR_STYLE" "$WOFI_STYLE" "$SWAYNC_STYLE" "$HYPRLOCK_SKIN")

if grep -q "@color1 " "$WAYBAR_STYLE" || grep -q "\$color1 " "$HYPRLOCK_SKIN"; then
    # Current: 1/5 -> Next: 6/13
    O1="@color1"; N1="@color6"
    O5="@color5"; N5="@color13"
    HO1="\$color1"; HN1="\$color6"
    HO5="\$color5"; HN5="\$color13"
    MSG="Cycle: 1/5 -> 6/13"
elif grep -q "@color6 " "$WAYBAR_STYLE" || grep -q "\$color6 " "$HYPRLOCK_SKIN"; then
    # Current: 6/13 -> Next: 13/6
    O1="@color6"; N1="@color13"
    O5="@color13"; N5="@color6"
    HO1="\$color6"; HN1="\$color13"
    HO5="\$color13"; HN5="\$color6"
    MSG="Cycle: 6/13 -> 13/6"
else
    # Current: 13/6 (or fallback) -> Next: 1/5
    O1="@color13"; N1="@color1"
    O5="@color6"; N5="@color5"
    HO1="\$color13"; HN1="\$color1"
    HO5="\$color6"; HN5="\$color5"
    MSG="Cycle: 13/6 -> 1/5"
fi

for FILE in "${FILES[@]}"; do
    if [ -f "$FILE" ]; then
        if [[ "$FILE" == *".conf" ]]; then
            sed -i "s/$HO1 /$HN1 /g" "$FILE"
            sed -i "s/$HO5 /$HN5 /g" "$FILE"
        else
            sed -i "s/$O1;/$N1;/g" "$FILE"
            sed -i "s/$O5;/$N5;/g" "$FILE"
            sed -i "s/$O1\([, )]\)/$N1\1/g" "$FILE"
            sed -i "s/$O5\([, )]\)/$N5\1/g" "$FILE"
        fi
    fi
done

killall waybar && sleep 0.1 && systemctl --user restart waybar &
swaync-client -rs

echo "$MSG"
