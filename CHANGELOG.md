Releases: NeKoRoSYS/NeKoRoSHELL

# 1.3.3 - Quick Fix

playsound command got accidentally removed, i brought it back.
<br>

# 1.3.2

Navbar Hover mode's TRIGGER_SIZE value has been separated into ACTIVATE_SIZE and DEACTIVATE_SIZE. Making it so that reaching for the toolbar on some app won't accidentally trigger the navbar easily.
<br>

# 1.3.1 - Quick Optimizations

Optimized navbar modes.
<br>

# 1.3 - Navbar QOL

Navbar (waybar) now has three modes!

- Static: Pre-1.3 navbar behavior. Navbar stays on top top all the time.
- Dynamic: Navbar appears only if there's a visible windows.
- Hover: Navbar appears if mouse hovers to a specified area. Navbar skins system supports custom trigger areas, so don't worry about putting your bars anywhere.
<br>

# 1.2 - More Polishing
## General:

- All UI features provided by waybar, SwayNC, hyprlock, and wofi now have generic names: navbar, control centre, lockscreen, and launcher, respectively.
- Moved a couple of bash scripts from the hypr/scripts folder.
- hyprland.conf now uses relative paths.
- Merged customize-feature and customize at the bin folder.

## QOL:

- Better light mode support.
- Adjusted wofi dmenu behavior. They will now toggle on and off when you press a keybind that opens wofi.
- Optimized apply-theme.sh, it now extracts color from the cached low-res thumbnails to reduce processing time while still outputting the same results!

## Legacy Theme
Legacy is stable now! Coloring should be consistent across all panels and windows, on light and dark modes.

- Refined waybar legacy layout.
- Adjusted SwayNC legacy style.
<br>

# 1.1 - Overhaul

I am switching to a more mature versioning system because I realized that the project still needs a lot of work.

- install.sh is now more robust.
- Removed upgradium.sh from the repo.
- Updated hypr config directories.
- Switched to SwayNC for handling notifications
  - Certain actions like changing wallpaper, running an app, and taking a screenshot will now send a notification.

Updates to theming system have been made:
- Introduction of Skins system: It is now possible to select styles and layouts for waybar, SwayNC, wofi, and hyprlock!
  - Legacy theme: Colors feel more unified across notifications, dmenus, and windows in general.
- Added light mode support.
- Added support for picking video wallpapers randomly.
- Added preview thumbnails for each wallpaper.
- It is now possible to paste image and video links at the wofi prompt to automatically download, save, and set a wallpaper from the internet.

Known issues:
- Blue light filter option in the notifications center does not work as intended.
<br>

# 1.0

I am now confident to say that this rice is now a functional frontend for Arch Linux.
