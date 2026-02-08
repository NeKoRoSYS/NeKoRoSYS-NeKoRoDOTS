 #!/bin/bash

pkill -f ~/.config/hypr/scripts/eject-forbidden.sh || true

# 1. Top Left

#kitty --hold -o font_size=10 --class fastfetch-grid -e fastfetch & #1080p
kitty --hold -o font_size=7 --class fastfetch-grid -e fastfetch & #720p
sleep 0.3


# 2. Top Right

hyprctl dispatch layoutmsg presel r

kitty --class clock-grid -e tty-clock -c -t  &

sleep 0.1


# 3. Bottom Left

hyprctl dispatch focuswindow class:fastfetch-grid hyprctl dispatch layoutmsg presel d 

kitty --class cava-grid -e cava & sleep 0.1


# 4. Bottom Right

hyprctl dispatch focuswindow class:clock-grid

hyprctl dispatch layoutmsg presel d

#kitty -o font_size=7 --class btop-grid -e btop & #1080p 
kitty -o font_size=6 --class btop-grid -e btop & #720p &

sleep 2 && bash ~/.config/hypr/scripts/eject-forbidden.sh
