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

echo -e "${BLUE}Detecting operating system...${NC}"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    if [ "$OS" = "linuxmint" ] || [ "$OS" = "pop" ]; then
        OS="ubuntu"
    fi
else
    echo -e "${RED}Cannot detect operating system. /etc/os-release not found.${NC}"
    exit 1
fi

echo -e "${GREEN}Detected OS: $OS${NC}"

echo -e "${BLUE}Starting installation...${NC}"

echo -e "${BLUE}Installing system dependencies...${NC}"

case "$OS" in
    arch|endeavouros|manjaro)
        if command -v paru &> /dev/null; then
            AUR_HELPER="paru"
        elif command -v yay &> /dev/null; then
            AUR_HELPER="yay"
        else
            echo -e "${RED}Error: yay or paru is required for Arch.${NC}"
            exit 1
        fi
        
        if [ -f "pkglist.txt" ]; then
            $AUR_HELPER -S --needed --noconfirm - < pkglist.txt
        fi
        ;;

    fedora)
        if [ -f "pkglist-fedora.txt" ]; then
            sudo dnf install -y $(cat pkglist-fedora.txt)
        else
            echo -e "${RED}pkglist-fedora.txt not found!${NC}"
        fi
        ;;

    ubuntu|debian)
        if [ -f "pkglist-debian.txt" ]; then
            sudo apt-get update
            sudo apt-get install -y $(cat pkglist-debian.txt)
        else
            echo -e "${RED}pkglist-debian.txt not found!${NC}"
        fi
        ;;
        
    gentoo)
        if [ -f "pkglist-gentoo.txt" ]; then
            sudo emerge -av --noreplace $(cat pkglist-gentoo.txt)
        else
            echo -e "${RED}pkglist-gentoo.txt not found!${NC}"
        fi
        ;;

    *)
        echo -e "${RED}Unsupported OS: $OS. Please install dependencies manually.${NC}"
        echo -ne "Do you wish to continue with config deployment anyway? (y/n): "
        read -r continue_ans
        if [[ ! "$continue_ans" =~ ^[Yy]$ ]]; then
            exit 1
        fi
        ;;
esac

echo -e "${BLUE}Checking for packages that require Cargo (Rust)...${NC}"

if command -v cargo &> /dev/null; then
    export PATH="$HOME/.cargo/bin:$PATH"

    if ! command -v wallust &> /dev/null; then
        echo -e "${BLUE}Installing wallust via cargo... This may take a few minutes.${NC}"
        cargo install wallust
    else
        echo -e "${GREEN}wallust is already installed.${NC}"
    fi

    if ! command -v swww &> /dev/null; then
        echo -e "${BLUE}Installing swww via cargo... This may take a few minutes.${NC}"
        cargo install --git https://github.com/LGFae/swww.git
    else
        echo -e "${GREEN}swww is already installed.${NC}"
    fi

    if ! grep -q 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.bashrc; then
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
    fi
    if [ -f ~/.zshrc ] && ! grep -q 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.zshrc; then
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc
    fi
else
    echo -e "${RED}Cargo is not installed. Some tools (wallust, swww) could not be verified or installed.${NC}"
fi

if ! command -v flatpak &> /dev/null; then
    echo -e "${RED}Error: flatpak is not installed.${NC}"
    exit 1
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

CONFIGS=(btop cava fastfetch hypr hypremoji kitty rofi swaync systemd wallpapers wallust waybar)
for conf in "${CONFIGS[@]}"; do
    backup_config "$HOME/.config/$conf"
done

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

if command -v "bash" >/dev/null 2>&1; then
    echo "bash is installed. Appending paths..."
    grep -v -x -f ~/.bashrc .bashrc >> ~/.bashrc
fi

if command -v "zsh" >/dev/null 2>&1; then
    echo "zsh is installed. Appending paths..."
    grep -v -x -f ~/.zshrc .zshrc >> ~/.zshrc
fi

cp -r .p10k.zsh ~/
cp .face.icon ~/
cp change-avatar.sh ~/
cp -r bin ~/


echo -e "${BLUE}Compiling C++ Daemons...${NC}"
g++ -O3 -o ~/bin/navbar-hover bin/source/navbar-hover.cpp
g++ -O3 -o ~/bin/navbar-watcher bin/source/navbar-watcher.cpp

echo -e "${BLUE}Setting script permissions...${NC}"
find ~/.config/ -name "*.sh" -exec chmod +x {} + 2>/dev/null
find ~/bin/ -name "*.sh" -exec chmod +x {} + 2>/dev/null
find ~/bin/ -name "*" -exec chmod +x {} + 2>/dev/null

if command -v "systemctl" >/dev/null 2>&1; then
    echo -e "${BLUE}Enabling waybar...${NC}"
    systemctl --user enable waybar.service
    echo -e "${BLUE}Enabling SwayNC...${NC}"
    systemctl --user enable swaync.service
else
    echo -e "${RED}Cannot run command 'systemctl'. Please enable the waybar and SwayNC services manually.${NC}"
fi

echo -e "${GREEN}Installation complete! Please restart your session.${NC}"
