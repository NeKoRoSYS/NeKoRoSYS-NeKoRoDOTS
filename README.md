> [!TIP]
> Please star the repo if you like the dotfiles. Thank you 🙏
<br>

![Screenshot](showcase/image.png) 
<br>
<br>

# NeKoRoDOTS 
<br>

The best way to say "I use Arch btw 🤓" is if your desktop profile looks sleek and suave.

**NeKoRoDOTS** aims to provide an out-of-the-box, clean and reliable, generic, and modular framework that lets you easily customize your desktop experience with simple UI design philosophy in mind.
<br>
<br>

<div align="center">
| 📌 **Table of Contents** |
| :---: |
| 🔗 [Dependencies](#dependencies) |
| 🚀 [Features](#features) |
| 🔨 [Skins and Layouts](#skins-and-layouts) |
| 🤔 [Optional](#optional) |
| 💸 [Sponsorship](#sponsorship) |
| 🫂 [Contribution](#contribution) |
</div>
<br>

## Dependencies

> [!CAUTION]
> **HARDWARE SPECIFIC CONFIGURATION**<br>
>
> Some environment variables and params at `~/.config/hypr/configs/environment.conf/` and `~/.config/hypr/scripts/set-wallpaper.sh/` (also check the `check-video.sh` script, `mpvpaper` uses a "hwdec=nvdec" param) **require an NVIDIA graphics card**. Although it may be generally safe to leave it as is upon installing to a machine without such GPU, I recommend commenting it out or replacing it with a variable that goes according to your GPU.
> 
> The [System Booting](#system-booting) section contains settings specifically optimized for a dual-GPU laptop (Intel 620/Nvidia 940MX). 
> **Do not** copy the `GRUB_CMDLINE_LINUX_DEFAULT` or `mkinitcpio` modules unless you have identical hardware, as this may **prevent your system from booting**.

- Auto-pause animated wallpapers via [mpvpaper-stop](https://github.com/pvtoari/mpvpaper-stop) (dependencies: cmake, cjson)
  - Used at `set-wallpaper.sh` and `check-video.sh` in `~/.config/hypr/scripts/wallpapers/` to save CPU/RAM usage.
 
- This rice uses `wofi` to run actions and apps.
  - Some apps like `mpvpaper` needs to be ran using `prime-run` and `gamemoderun`
    - Install via `sudo pacman -S nvidia-prime gamemode`.
  - (Automatically provided by `pkglist.txt` if you used the `install.sh` bash file)

- `hyprland` uses `hypridle` and `hyprlock`.
  - Install them via `sudo pacman -S hyprlock hypridle`. (Automatically provided by `pkglist.txt` if you used the `install.sh` bash file)

- Waybar was set up to use `kitty`, `Mozilla Firefox`, and `dolphin`. You can change this if you want at `~/.config/waybar/config.jsonc`.

- The screenshot and clipboard features need `grim`, `slurp`, `hyprshot`, `wl-clipboard`, and `cliphist` to run.
  - Install them via `sudo pacman -S grim wl-clipboard cliphist`. (Automatically provided by `pkglist.txt` if you used the `install.sh` bash file)
<br>

## Features

NeKoRoDOTS focuses on simplicity and modularity.
<br>

### Roadmap

NeKoRoDOTS is currently being developed by one person (*cough* [CONTRIBUTING](https://github.com/NeKoRoSYS/NeKoRoDOTS/tree/main?tab=contributing-ov-file#) *cough*) and is constantly under rigorous quality assurance for improvement. We always aim to keep a "no-break" promise for every update so that you can safely update to later versions without expecting any breakages.

<div align="center">
| 📋 **TODO** | **STATUS** |
| :---: | :---: |
| Improve base "legacy" theme | ✅ |
| Implement base functionality | ✅ |
| Implement base QOL features | ✅ |
| Optimizations | ✅ |
| Color Handling - Replace pywal6 with wallust (BETA, [Issues](https://github.com/NeKoRoSYS/NeKoRoDOTS/issues/1)) | 🛑 |
| Dmenu Overhaul - Replace wofi with rofi | 🛠 |
| Support for other distros | ⏳ |
| Qt and Kvantum integration | 🤔 |
</div>

The following are what NeKoRoDOTS currently offers:
- **One-tap Installer Script**
  - Use `git clone https://github.com/NeKoRoSYS/NeKoRoDOTS`
  - Then `cd NeKoRoDOTS`
  - and finally, `bash install.sh` to install the dotfiles.
    - You can freely customize `flatpak.txt` and `pkglist.txt` before running `install.sh`.
    - The installer assumes you already installed `base-devel`, `git`, `yay`, `flatpak`.
    - The installer assumes you have turned on mirror link downloads for `pacman`.
    - **The installer is safe.** It backs up your pre-existing .config folders. (If you have any)
    - The installer automatically handles assigning your monitors at `~/.config/hypr/configs/monitors.conf/` and replaces every occurence of `/home/nekorosys/` with your username for your own convenience.
   
- **Window Controls**
  - Maximize
  - Fullscreen
  - Toggle Opacity
  - Toggle Floating Window
  - Pseudo-floating/organized windows
  - Change tile placement

- **Copying and Pasting**
  - Screenshot support via `hyprshot` .
  - Clipboard history via `cliphist`.
 
- **Notificications Handling**
  - Uses `SwayNC` for a dedicated notification center with customizable buttons and options.
 
- **Smart Navbar**
  - Uses bash script wrappers for `waybar` for the modes: Static, Dynamic, and Hover.
<p align="center">
  <img src="https://github.com/NeKoRoSYS/NeKoRoDOTS/blob/main/showcase/navbar-modes.gif" alt="Navbar Demo" />
</p>

- **Advanced Customization - Make NeKoRoDOTS YOURS!**
  - NeKoRoDOTS is not just an identity, it is a framework. This repo gives you at most 2 pre-installed out-of-the-box layouts/styling for waybar, hyprlock, and SwayNC. The best part? You can make your own!
  - Credits to [iyiolacak](https://github.com/iyiolacak/iyiolacak-swaync-config?tab=readme-ov-file), [justinmdickey](https://github.com/justinmdickey/publicdots/blob/main/.config/hypr/hyprlock.conf), and [mkhmtolzhas](https://github.com/mkhmtolzhas/mkhmtdots) for their amazing theming.
  - Switch to Dark and Light Mode
  - Select Waybar Skins
  - Select Wofi Skins
  - Select Hyprlock Layouts
  - Select SwayNC Styles
  - **Wallpaper Handling**
    - Supports both online (yes, online.) and offline image (via `swww`) and video (via `mpvpaper`) formats.
      - `mpvpaper` automatically stops if an app is on fullscreen mode to save CPU, RAM, or GPU space.
      - Paste image or video links with valid file extensions in the wofi prompt and the download will automatically be processed, saved, and set as your new wallpaper.
    - Border colors and UI elements have dynamic color schemes.
<br>

![Screenshot](showcase/image-5.png) 
<br>
<br>
<br>
![Screenshot](showcase/image-3.png) 
<br>
<br>
<br>
![Screenshot](showcase/image-1.png) 
<br>
<br>
<br>
![Screenshot](showcase/image-2.png) 
<br>
<br>

> [!WARNING]
> `start-dashboard.sh` creates a grid layout for a 1920x1080 display, however I also provided a 1280x720 version of the dashboard in `~/.config/hypr/windowrules.conf/`. Anyhow, if your monitor has a different resolution, my dashboard preset may not appear as intended; I recommend making your own dashboard using the same bash script.
<br>

## Desktop Customization
Make sure to analyze the directory structure of `~/.config/waybar/skins`, `~/.config/hypr/hyprlock/`, and `~/.config/hypr/swaync/`; and how the files (`hyprlock.conf`, `config.jsonc`, `colors.css`, `style.css`, `layout.jsonc`, `modules.jsonc`) include or import from each other. That way, you can easily create more options or looks to choose from!

You have two options:
- Install someone else's Waybar/Hyprlock setup and then manually adjust its files to correctly import or include; or
- Make your own. ¯\_(ツ)_/¯
<br>
<br>

![Screenshot](showcase/image-8.png) 
<br>
<br>
<br>
![Screenshot](showcase/image-7.png) 
<br>
<br>
<br>
![Screenshot](showcase/image-6.png) 
<br>
<br>

## Optional

Mostly personal notes just in case I switch over to another PC. Do NOT copy my Grub Linux CMDLINE and mkinitcpio modules unless you also have a laptop with old hybrid GPUs (Intel Graphics 620 and Nvidia GeForce 940mx).

### System Booting
- Use [MineGrub](https://github.com/Lxtharia/minegrub-world-sel-theme) theme for Grub.
- Identify GPU names.
- `/etc/modprobe.d/nvidia.conf`
  
  ```
  options nvidia NVreg_PreserveVideoMemoryAllocations=1
  options nvidia NVreg_EnableS0ixPowerManagement=1
  install nvidia_uvm /usr/bin/false
  ```
  
- Modify `/etc/default/grub`
  - `sudo pacman -S os-prober`
 
    ```
    GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet rd.udev.log_level=3 systemd.show_status=auto vt.global_cursor_default=0 nvidia_drm.modeset=1 nvidia_drm.fbdev=1 pci=noaer pcie_aspm=off nvme_core.default_ps_max_latency_us=0 nvidia.NVreg_EnableS0ixPowerManagement=1 intel_pstate=active i915.modeset=1 i915.enable_fbc=1 mitigations=off"
    ```

  - `GRUB_THEME="/boot/grub/themes/minegrub-world-selection/theme.txt"`
  - `GRUB_DISABLE_OS_PROBER=false`
  - `sudo grub-mkconfig -o /boot/grub/grub.cfg`
- Modify `/etc/mkinitcpio.conf` (`MODULES` for GPU and `HOOKS` for `plymouth` after `base udev`)
  - `sudo mkinitcpio -P`
 
### Boot Animations and Login
- Use `plymouth` and `greetd` (`nwg-hello`)

### Fix Boosted/Noisy Mic on OBS and Discord (pipewire)
- Install `alsa-utils` and `noise-suppression-for-voice`
  - `wpctl status`
  - `alsamixer`
  - `sudo alsactl store`
  - `nano ~/.config/pipewire/pipewire.conf.d/99-input-denoising.conf`

    ```spa json
    context.modules = [
    {  name = libpipewire-module-filter-chain
       args = {
          node.description = "Noise Canceling Source"
          media.name       = "Noise Canceling Source"
          filter.graph = {
              nodes = [
                {
                    type   = ladspa
                    name   = rnnoise
                    plugin = /usr/lib/ladspa/librnnoise_ladspa.so
                    label  = noise_suppressor_mono
                    control = {
                        "VAD Threshold (%)" = 50.0
                    }
                }
            ]
          }
          capture.props = {
              node.name   = "capture.rnnoise_source"
              node.passive = true
              audio.rate   = 48000
          }
          playback.props = {
              node.name   = "rnnoise_source"
              media.class = Audio/Source
              audio.rate   = 48000
          }
        }
      }
    ]
    ```

  - `wpctl set-default yourNoiceCancelledID` (find in `wpctl status`)

### Quality-of-Life
- Install [Hypremoji](https://github.com/Musagy/hypremoji)
- Install `blueman` and `r-quick-share` for seamless bluetooth support. (Works with Apple Airpods and android phone)
- Fix waybar tray disappearing after a certain amount of time.
  ```
  yay -S sni-qt
  ```
  Make sure you're not killing waybar using -SIGUSER2 when refreshing the config.
