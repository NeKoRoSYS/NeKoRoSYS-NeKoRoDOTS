#!/bin/bash

echo -e "# ======================================================= #"
echo -e "#             NeKoRoSHELL Installation Wizard             #"
echo -e "# ======================================================= #\n "

while true; do
    echo -ne "\033[0;34mDo you want to start the NeKoRoSHELL installation? (y/n): \033[0m"
    read -r yn
    case $yn in
        [yY]* ) break;;
        [nN]* ) echo -e "\033[0;31mInstallation aborted.\033[0m"; exit;;
        * ) echo "Please answer yes (y) or no (n).";;
    esac
done

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Starting installation...${NC}"

if ! command -v yay &> /dev/null; then
    echo -e "${RED}Error: yay is not installed.${NC}"
    exit 1
fi

if ! command -v flatpak &> /dev/null; then
    echo -e "${RED}Error: flatpak is not installed.${NC}"
    exit 1
fi

if [ -f "pkglist.txt" ]; then
    echo -e "${BLUE}Installing packages from pkglist.txt...${NC}"
    yay -S --needed --noconfirm $(cat pkglist.txt)
else
    echo -e "${RED}Warning: pkglist.txt not found! Skipping system pkgs.${NC}"
fi

if [ -f "flatpak.txt" ]; then
    echo -e "${BLUE}Installing packages from flatpak.txt using flatpak...${NC}"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    cat flatpak.txt | xargs flatpak install -y
else
    echo -e "${RED}Error: flatpak.txt not found!${NC}"
    exit 1
fi

backup_config() {
    if [ -d "$1" ]; then
        BACKUP_NAME="${1}_backup_$(date +%Y%m%d_%H%M%S)"
        echo -e "${BLUE}Backing up existing $(basename $1) to $(basename $BACKUP_NAME)${NC}"
        mv "$1" "$BACKUP_NAME"
    fi
}

backup_config ~/.config/btop
backup_config ~/.config/cava
backup_config ~/.config/mako
backup_config ~/.config/fastfetch
backup_config ~/.config/kitty
backup_config ~/.config/systemd
backup_config ~/.config/wallpapers
backup_config ~/.config/hypr
backup_config ~/.config/hypremoji
backup_config ~/.config/swaync
backup_config ~/.config/waybar
backup_config ~/.config/wofi

echo -e "${BLUE}Deploying configuration files...${NC}"
mkdir -p ~/.config
cp -rv .config ~/

MAPFILE=($(hyprctl monitors | grep "Monitor" | awk '{print $2}'))
MONITOR_COUNT=${#MAPFILE[@]}

if [ "$MONITOR_COUNT" -gt 0 ]; then
    PRIMARY_MONITOR=${MAPFILE[0]}
    echo -e "${BLUE}Detected $MONITOR_COUNT monitor(s). Primary: $PRIMARY_MONITOR${NC}"

    sed -i "s/eDP-1/$PRIMARY_MONITOR/g" "$HOME/.config/hypr/configs/monitors.conf"

    if [ "$MONITOR_COUNT" -ge 2 ]; then
        SECONDARY_MONITOR=${MAPFILE[1]}
        echo -e "${BLUE}Secondary monitor detected: $SECONDARY_MONITOR${NC}"
        sed -i "s/DP-1/$SECONDARY_MONITOR/g" "$HOME/.config/hypr/configs/monitors.conf"
    else
        echo -e "${BLUE}Only one monitor detected. Disabling secondary monitor line...${NC}"
        sed -i '/monitor=DP-1/s/^/#/' "$HOME/.config/hypr/configs/monitors.conf"
    fi
fi

SEARCH="/home/nekorosys"
REPLACE="/home/$USER"

echo -e "${BLUE}Replacing $SEARCH with $REPLACE in config files...${NC}"
find "$HOME/.config" -type f -print0 2>/dev/null | xargs -0 -r sed -i "s|$SEARCH|$REPLACE|g" 2>/dev/null

if [command -v "bash" >/dev/null 2>&1]; then
    echo "bash is installed. Appending paths..."
    grep -v -x -f ~/.bashrc .bashrc >> ~/.bashrc
fi

if [command -v "zsh" >/dev/null 2>&1]; then
    echo "zsh is installed. Appending paths..."
    grep -v -x -f ~/.zshrc .zshrc >> ~/.zshrc
fi

cp -r .p10k.zsh ~/
cp .face.icon ~/
cp change-avatar.sh ~/
cp bin ~/

echo -e "${BLUE}Setting script permissions...${NC}"
find ~/.config/ -name "*.sh" -exec chmod +x {} + 2>/dev/null
find ~/bin/ -name "*.sh" -exec chmod +x {} + 2>/dev/null
find ~/bin/ -name "*" -exec chmod +x {} + 2>/dev/null
echo -e "${BLUE}Enabling waybar...${NC}"
sudo systemctl enable ~/.config/systemd/user/waybar.service
echo -e "${BLUE}Enabling SwayNC...${NC}"
systemctl --user enable swaync.service

echo -e "${GREEN}Installation complete! Please restart your session.${NC}"
