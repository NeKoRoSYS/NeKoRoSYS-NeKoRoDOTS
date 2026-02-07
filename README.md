# NeKoRoSYS's Arch Dotfiles
Based on [mkhmtolzhas' rice](https://github.com/mkhmtolzhas/Invincible-Dots). I initially made this repo because installing Invincible Dots didn't seem to work. Hence, I rebuilt it from the ground up using a lot of the repo's already-working parts so that it works with Hyprland's later versions. Why this fork stands out, you may ask? I added my own flavor to it, such as the support for video wallpapers; a couple of bug fixes at the keybinds config file (specifically, the bug that lets you open infinite instances of wofi which is very unoptimal); and a lot more!
<br>
<br>
| :---: |
| Table of Contents |
| [Dependencies](#dependencies) |
| [Features](#features) |
| [Notes](#notes) |
<br>
<br>
<br>
![Screenshot](image.png) 
<br>
<br>
![Screenshot](image-3.png) 
<br>
<br>
![Screenshot](image-2.png) 
<br>
<br>
## Dependencies
- Auto-pause animated wallpapers via [mpvpaper-stop](https://github.com/pvtoari/mpvpaper-stop) (dependencies: cmake, cjson)
  - Used at `set-wallpaper.sh` and `check-video.sh` in `~/.config/hypr/scripts/wallpapers/` to save CPU/RAM usage.
- This rice uses `wofi` to run actions and apps.
  - Install via `sudo pacman -S wofi`.
  - Some apps like `mpvpaper` needs to be ran using `prime-run` and `gamemoderun`
    - Install via `sudo pacman -S nvidia-prime gamemode`.
  - (Automatically provided by `pkglist.txt` if you used the `install.sh` bash file)
- `hyprland` uses `hyprdile` and `hyprlock`.
  - Install them via `sudo pacman -S hyprlock hypridle`. (Automatically provided by `pkglist.txt` if you used the `install.sh` bash file)
- Waybar was set up to use `kitty`, `Mozilla Firefox`, and `dolphin`. You can change this if you want at `~/.config/waybar/config.jsonc`.
- The screenshot and clipboard features need `grim`, `slurp`, `hyprshot`, `wl-clipboard`, and `cliphist` to run.
  - Install them via `sudo pacman -S grim wl-clipboard cliphist`. (Automatically provided by `pkglist.txt` if you used the `install.sh` bash file)
<br>

## Features
- **One-tap Installer Script**
  - use `git clone https://github.com/NeKoRoSYS/NeKoRoSYS-Arch-Dotfiles`
  - then `cd NeKoRoSYS-Arch-Dotfiles`
  - and finally, `bash install.sh` to install the dotfiles.
    - You can freely customize `flatpak.txt` and `pkglist.txt` before running `install.sh`.
    - The installer assumes you already installed `base-devel`, `git`, `yay`, `flatpak`.
    - The installer assumes you have turned on mirror link downloads for `pacman`.
    - Don't be scared if `sed` says it can't read a file or directory in the installer. It's part of the function to replace every occurence of `/home/nekorosys` with your username and it simply cant find one at those locations.
- **Window Controls**
  - Maximize
  - Fullscreen
  - Toggle Floating Window
  - Pseudo-floating/organized windows
  - Change tile placement
- **Copying and Pasting**
  - Screenshot support via `hyprshot` .
  - Clipboard history via `cliphist`.
- **Advanced Wallpaper Handling**
  - Supports both image (via `swww`) and video (via `mpvpaper`) formats.
    - `mpvpaper` automatically stops if an app is on fullscreen mode to save CPU, RAM, or GPU space.
  - Border colors and UI elements have dynamic color schemes.
- **Familiar Waybar Setup**
  - Sleek and straightforward design.
  - Built to feel like a Windows taskbar.
    - Choose to start an app, change workspaces, or select power options like Lock, Sleep, Shut Down, Reboot, and Sign Out.
<br>

## Notes
- **IMPORTANT:** This rice originally uses my dual-monitor setup. Enter `grep -r "DP-1" ~/.config/` and `grep -r "eDP-1" ~/.config/` to find all occurences of my monitors being mentioned so you can replace them with your own.
  - `start-dashboard.sh` creates a grid layout for a 1920x1080 display, however I also provided a 1280x720 version of the dashboard in `~/.config/hypr/windowrules.conf/`.
<br>

## TODO
- Improve Hyprlock UI

<br>

## Optional
Mostly personal notes just in case I switch over to another PC.
- Use [MineGrub](https://github.com/Lxtharia/minegrub-world-sel-theme) theme for Grub.
- Identify GPU names.
- `/etc/modprobe.d/nvidia.conf`
  - `options nvidia NVreg_PreserveVideoMemoryAllocations=1`
  - `options nvidia NVreg_EnableS0ixPowerManagement=1`
  - `install nvidia_uvm /usr/bin/false`
- Modify `/etc/default/grub`
  - `sudo pacman -S os-prober`
  - `GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet rd.udev.log_level=3 systemd.show_status=auto vt.global_cursor_default=0 nvidia_drm.modeset=1 nvidia_drm.fbdev=1 pci=noaer pcie_aspm=off nvme_core.default_ps_max_latency_us=0 nvidia.NVreg_EnableS0ixPowerManagement=1 intel_pstate=active i915.modeset=1 i915.enable_fbc=1 mitigations=off"`
  - `GRUB_THEME="/boot/grub/themes/minegrub-world-selection/theme.txt"`
  - `GRUB_DISABLE_OS_PROBER=false`
  - `sudo grub-mkconfig -o /boot/grub/grub.cfg`
- Modify `/etc/mkinitcpio.conf` (`MODULES` for GPU and `HOOKS` for `plymouth` after `base udev`)
  - `sudo mkinitcpio -P`
- Use `plymouth` and `greetd` (`nwg-hello`)
