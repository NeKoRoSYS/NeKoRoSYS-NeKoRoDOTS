#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
cd "$SCRIPT_DIR" || { echo -e "${RED}Failed to navigate to script directory.${NC}"; exit 1; }

echo -e "# ======================================================= #"
echo -e "#            NeKoRoSHELL Installation Wizard              #"
echo -e "# ======================================================= #\n "

echo -e "${BLUE}Please choose your installation type:${NC}"
echo -e "  ${GREEN}Minimal${NC}     - Backup existing .config files, copy the new .config files, and replace the hardcoded directories, but don't install dependencies."
echo -e "  ${GREEN}Compilation${NC} - Backup existing .config files, copy the new .config files over, replace the hardcoded directories, and install every dependency.\n"

INSTALL_TYPE=""
while true; do
    echo -ne "${BLUE}Type 'Minimal' or 'Compilation' to proceed (or 'exit' to abort): ${NC}"
    read -r choice
    choice="${choice,,}"

    if [[ "$choice" == "minimal" ]]; then
        INSTALL_TYPE="minimal"
        echo -e "${GREEN}Minimal installation selected.${NC}"
        break
    elif [[ "$choice" == "compilation" ]]; then
        INSTALL_TYPE="compilation"
        echo -e "${GREEN}Compilation installation selected.${NC}"
        
        echo -e "${BLUE}Caching sudo credentials for dependency installation...${NC}"
        sudo -v
        while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
        
        break
    elif [[ "$choice" == "exit" ]]; then
        echo -e "${RED}Installation aborted.${NC}"
        exit 0
    else
        echo -e "${RED}Invalid input. Please type 'Minimal' or 'Compilation'.${NC}"
    fi
done

echo -e "${BLUE}Starting $INSTALL_TYPE installation...${NC}"

# ==============================================================================
# DEPENDENCY INSTALLATION (Compilation Mode Only)
# ==============================================================================

if [[ "$INSTALL_TYPE" == "compilation" ]]; then

    echo -e "${BLUE}Detecting operating system...${NC}"

    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        if [[ "$OS" == "linuxmint" ]] || [[ "$OS" == "pop" ]]; then
            OS="ubuntu"
        fi
    else
        echo -e "${RED}Cannot detect operating system. /etc/os-release not found.${NC}"
        exit 1
    fi

    echo -e "${GREEN}Detected OS: $OS${NC}"
    echo -e "${BLUE}Installing system dependencies...${NC}"

    case "$OS" in
        arch|endeavouros|manjaro)
            if command -v paru &> /dev/null; then
                AUR_HELPER="paru"
            elif command -v yay &> /dev/null; then
                AUR_HELPER="yay"
            else
                echo -e "${RED}Error: yay or paru is required for Arch-based systems.${NC}"
                exit 1
            fi
            
            if [[ -f "pkglist-arch.txt" ]]; then
                $AUR_HELPER -S --needed --noconfirm - < pkglist-arch.txt
            else
                echo -e "${RED}Warning: pkglist-arch.txt not found!${NC}"
            fi
            ;;

        fedora)
            if [[ -f "pkglist-fedora.txt" ]]; then
                grep -vE '^\s*#|^\s*$' pkglist-fedora.txt | xargs sudo dnf install -y
            else
                echo -e "${RED}Warning: pkglist-fedora.txt not found!${NC}"
            fi
            ;;

        ubuntu|debian)
            echo -e "${RED}WARNING: Debian/Ubuntu do not provide Hyprland or its ecosystem natively.${NC}"
            echo -e "${RED}Ensure you have installed them via a 3rd party PPA/script first.${NC}"
            sleep 3
            if [[ -f "pkglist-debian.txt" ]]; then
                sudo apt-get update
                grep -vE '^\s*#|^\s*$' pkglist-debian.txt | xargs sudo apt-get install -y
            else
                echo -e "${RED}Warning: pkglist-debian.txt not found!${NC}"
            fi
            ;;
            
        gentoo)
            if [[ -f "pkglist-gentoo.txt" ]]; then
                grep -vE '^\s*#|^\s*$' pkglist-gentoo.txt | xargs sudo emerge -av --noreplace
            else
                echo -e "${RED}Warning: pkglist-gentoo.txt not found!${NC}"
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

        for pkg in wallust swww; do
            if ! command -v "$pkg" &> /dev/null; then
                echo -e "${BLUE}Installing $pkg via cargo...${NC}"
                if [[ "$pkg" == "swww" ]]; then
                    cargo install --git https://github.com/LGFae/swww.git
                else
                    cargo install "$pkg"
                fi
            else
                echo -e "${GREEN}$pkg is already installed.${NC}"
            fi
        done
    else
        echo -e "${RED}Cargo is not installed. Skipping wallust and swww.${NC}"
    fi

    echo -e "${BLUE}Checking for packages that require Go...${NC}"
    if command -v go &> /dev/null; then
        export PATH="$HOME/go/bin:$PATH"

        if ! command -v cliphist &> /dev/null; then
            echo -e "${BLUE}Installing cliphist via Go...${NC}"
            go install go.senan.xyz/cliphist@latest
        else
            echo -e "${GREEN}cliphist is already installed.${NC}"
        fi
    else
        echo -e "${RED}Go is not installed. Skipping cliphist.${NC}"
    fi

    if command -v flatpak &> /dev/null; then
        if [[ -f "flatpak.txt" ]]; then
            echo -e "${BLUE}Installing flatpak packages...${NC}"
            sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
            grep -vE '^\s*#|^\s*$' flatpak.txt | xargs sudo flatpak install -y flathub
        else
            echo -e "${RED}Warning: flatpak.txt not found!${NC}"
        fi
    else
        echo -e "${RED}Warning: flatpak is not installed. Skipping flatpak dependencies.${NC}"
    fi
fi

# ==============================================================================
# CONFIG DEPLOYMENT (Both Minimal & Compilation)
# ==============================================================================

backup_config() {
    if [[ -d "$1" ]]; then
        local base_name
        base_name=$(basename "$1")
        local backup_name="${1}_backup_$(date +%Y%m%d_%H%M%S)"
        echo -e "${BLUE}Backing up existing $base_name to $(basename "$backup_name")${NC}"
        mv "$1" "$backup_name"
    fi
}

CONFIGS=(btop cava fastfetch hypr hypremoji kitty rofi swaync systemd wallpapers wallust waybar)
for conf in "${CONFIGS[@]}"; do
    backup_config "$HOME/.config/$conf"
done

echo -e "${BLUE}Deploying configuration files...${NC}"
mkdir -p "$HOME/.config"
cp -rv .config/* "$HOME/.config/" 2>/dev/null || echo -e "${RED}Warning: Some configs missing in source directory.${NC}"

echo -e "${BLUE}Detecting monitors...${NC}"
declare -a MONITOR_LIST

if [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]] && command -v hyprctl &> /dev/null; then
    echo -e "${BLUE}Active Hyprland session detected. Using hyprctl...${NC}"
    mapfile -t MONITOR_LIST < <(hyprctl monitors | awk '/Monitor/ {print $2}')
else
    echo -e "${BLUE}Hyprland is not running. Querying sysfs for hardware...${NC}"
    for f in /sys/class/drm/*/status; do
        if grep -q "^connected$" "$f" 2>/dev/null; then
            dir=$(dirname "$f")
            name=$(basename "$dir")
            monitor_name="${name#*-}"
            if [[ ! " ${MONITOR_LIST[*]} " =~ " ${monitor_name} " ]]; then
                MONITOR_LIST+=("$monitor_name")
            fi
        fi
    done
fi

MONITOR_COUNT=${#MONITOR_LIST[@]}
MONITOR_CONF="$HOME/.config/hypr/configs/monitors.conf"

if [[ "$MONITOR_COUNT" -gt 0 ]] && [[ -f "$MONITOR_CONF" ]]; then
    PRIMARY_MONITOR=${MONITOR_LIST[0]}
    echo -e "${GREEN}Detected $MONITOR_COUNT monitor(s). Primary: $PRIMARY_MONITOR${NC}"

    sed -i "s/eDP-1/$PRIMARY_MONITOR/g" "$MONITOR_CONF"

    if [[ "$MONITOR_COUNT" -ge 2 ]]; then
        SECONDARY_MONITOR=${MONITOR_LIST[1]}
        echo -e "${GREEN}Secondary monitor detected: $SECONDARY_MONITOR${NC}"
        sed -i "s/DP-1/$SECONDARY_MONITOR/g" "$MONITOR_CONF"
    else
        echo -e "${BLUE}Only one monitor detected. Disabling secondary monitor line...${NC}"
        sed -i '/monitor=DP-1/s/^/#/' "$MONITOR_CONF"
    fi
elif [[ ! -f "$MONITOR_CONF" ]]; then
    echo -e "${RED}Warning: $MONITOR_CONF not found. Skipping monitor setup.${NC}"
else
    echo -e "${RED}Warning: Could not automatically detect any monitors.${NC}"
fi

SEARCH="/home/nekorosys"
REPLACE="$HOME"

echo -e "${BLUE}Replacing hardcoded paths ($SEARCH -> $REPLACE)...${NC}"
find "$HOME/.config" -type f -print0 2>/dev/null | xargs -0 -r sed -i "s|$SEARCH|$REPLACE|g" 2>/dev/null

inject_shell_config() {
    local shell_rc="$1"
    local source_rc="$2"
    
    if command -v "${shell_rc##*.}" >/dev/null 2>&1 && [[ -f "$source_rc" ]]; then
        echo "Appending configs to $shell_rc..."
        if ! grep -q "# --- NeKoRoSHELL START ---" "$shell_rc" 2>/dev/null; then
            echo -e "\n# --- NeKoRoSHELL START ---" >> "$shell_rc"
            cat "$source_rc" >> "$shell_rc"
            
            [[ -d "$HOME/.cargo/bin" ]] && echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$shell_rc"
            [[ -d "$HOME/go/bin" ]] && echo 'export PATH="$HOME/go/bin:$PATH"' >> "$shell_rc"
            
            echo -e "# --- NeKoRoSHELL END ---" >> "$shell_rc"
        else
            echo -e "${GREEN}NeKoRoSHELL configs already present in $shell_rc. Skipping append.${NC}"
        fi
    fi
}

inject_shell_config "$HOME/.bashrc" ".bashrc"
inject_shell_config "$HOME/.zshrc" ".zshrc"

[[ -f .p10k.zsh ]] && cp .p10k.zsh "$HOME/"
[[ -f .face.icon ]] && cp .face.icon "$HOME/"
[[ -f change-avatar.sh ]] && cp change-avatar.sh "$HOME/"
[[ -d bin ]] && cp -r bin "$HOME/"

# ==============================================================================
# DOWNLOADING & COMPILING (Compilation Mode Only)
# ==============================================================================

if [[ "$INSTALL_TYPE" == "compilation" ]]; then
    if ! command -v hyprshot &> /dev/null; then
        echo -e "${BLUE}Downloading hyprshot...${NC}"
        mkdir -p "$HOME/bin"
        curl -sLo "$HOME/bin/hyprshot" https://raw.githubusercontent.com/Gustash/Hyprshot/main/hyprshot
        chmod +x "$HOME/bin/hyprshot"
    fi

    if [[ ! -d "$HOME/powerlevel10k" ]]; then
        echo -e "${BLUE}Cloning Powerlevel10k theme...${NC}"
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"
    fi

    if ! command -v g++ &> /dev/null; then
        echo -e "${RED}g++ is not installed. Please install build tools to compile the C++ daemons.${NC}"
    else
        echo -e "${BLUE}Compiling C++ Daemons...${NC}"
        mkdir -p "$HOME/bin"
        
        if [[ -f "bin/source/navbar-hover.cpp" ]]; then
            g++ -O3 -o "$HOME/bin/navbar-hover" bin/source/navbar-hover.cpp
        else
            echo -e "${RED}Warning: bin/source/navbar-hover.cpp not found.${NC}"
        fi
        
        if [[ -f "bin/source/navbar-watcher.cpp" ]]; then
            g++ -O3 -o "$HOME/bin/navbar-watcher" bin/source/navbar-watcher.cpp
        else
            echo -e "${RED}Warning: bin/source/navbar-watcher.cpp not found.${NC}"
        fi
    fi
fi

# ==============================================================================
# PERMISSIONS & SERVICES (Both Minimal & Compilation)
# ==============================================================================

echo -e "${BLUE}Setting script permissions...${NC}"
find "$HOME/.config/" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null
if [[ -d "$HOME/bin" ]]; then
    find "$HOME/bin/" -type f -exec chmod +x {} + 2>/dev/null
fi

if command -v systemctl >/dev/null 2>&1; then
    echo -e "${BLUE}Enabling Wayland services...${NC}"
    systemctl --user enable waybar.service 2>/dev/null
    systemctl --user enable swaync.service 2>/dev/null
else
    echo -e "${RED}Cannot run systemctl. Please enable waybar and SwayNC manually.${NC}"
fi

echo -e "${GREEN}Installation complete! Please restart your session to apply all changes.${NC}"
