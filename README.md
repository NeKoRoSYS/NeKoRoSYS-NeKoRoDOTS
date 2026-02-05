# NeKoRoSYS's Arch Linux Rice
Based on [mkhmtolzhas' rice](https://github.com/mkhmtolzhas/Invincible-Dots).

## Notes
- This repo assumes you already installed `base-devel`, `git`, `yay`, `flatpak`.
- This repo assumes you have turned on mirror link downloads for `pacman`.
- Don't be scared if sed says it can't read a file or directory in the installer. It's part of the function to replace every occurence of `"/home/nekorosys"` with your username and it simply cant find one at those locations.
- You can freely customize `flatpak.txt` and `pkglist.txt`
- **IMPORTANT** This rice originally uses my dual-monitor setup. Enter `grep -r "DP-1" ~/.config/` and `grep -r "eDP-1" ~/.config/` to find all occurences of my monitors being mentioned so you can replace them with your own.
  - `start-dashboard.sh` creates a grid layout for a 1920x1080 display, it may not work the same for you if your monitor has a different resolution.


## Other Dependencies (Read them to install properly)
- Assuming sddm is installed, use this https://github.com/uiriansan/SilentSDDM as a theme
- Auto-stop animated wallpapers https://github.com/pvtoari/mpvpaper-stop (dependencies: cmake, cjson)
