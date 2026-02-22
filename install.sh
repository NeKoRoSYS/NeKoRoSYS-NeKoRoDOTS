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

# ==============================================================================
# ACTIVE BIN DIRECTORY DETECTION
# ==============================================================================
echo -e "${BLUE}Detecting active user bin directory...${NC}"
if [[ -d "$HOME/.local/bin" ]]; then
    USER_BIN_DIR="$HOME/.local/bin"
elif [[ -d "$HOME/bin" ]]; then
    USER_BIN_DIR="$HOME/bin"
else
    USER_BIN_DIR="$HOME/.local/bin"
fi
echo -e "${GREEN}Using $USER_BIN_DIR as the target bin directory.${NC}\n"

echo -e "${BLUE}Please choose your installation type:${NC}"
echo -e "  ${GREEN}Minimal${NC}     - Backup existing .config files, copy the new .config files, and replace the hardcoded directories, but don't install dependencies."
echo -e "  ${GREEN}Compilation${NC} - Backup existing .config files, copy the new .config files over, replace the hardcoded directories, and install every dependency.\n"

cleanup() {
    if [[ -n "$SUDO_PID" ]]; then
        kill "$SUDO_PID" 2>/dev/null
    fi
}
trap cleanup EXIT

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
        ( while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done ) 2>/dev/null &
        SUDO_PID=$!
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
            
            if [[ -f "packages/pkglist-arch.txt" ]]; then
                packages=$(sed 's/["'\'']//g' packages/pkglist-arch.txt | tr ' ' '\n' | grep -v -E '^\s*$|^#')
                
                for pkg in $packages; do
                    echo -e "${BLUE}Installing: $pkg${NC}"
                    $AUR_HELPER -S --needed --noconfirm "$pkg" || echo -e "${RED}Failed to install $pkg. Skipping...${NC}"
                done
            else
                echo -e "${RED}Warning: packages/pkglist-arch.txt not found!${NC}"
            fi
            ;;

        fedora)
            if [[ -f "packages/pkglist-fedora.txt" ]]; then
                packages=$(sed 's/["'\'']//g' packages/pkglist-fedora.txt | tr ' ' '\n' | grep -v -E '^\s*$|^#')
                for pkg in $packages; do
                    echo -e "${BLUE}Installing: $pkg${NC}"
                    sudo dnf install -y "$pkg" || echo -e "${RED}Failed to install $pkg. Skipping...${NC}"
                done
            else
                echo -e "${RED}Warning: packages/pkglist-fedora.txt not found!${NC}"
            fi
            ;;

        ubuntu|debian)
            echo -e "${RED}WARNING: Debian/Ubuntu do not provide Hyprland or its ecosystem natively.${NC}"
            echo -e "${RED}Ensure you have installed them via a 3rd party PPA/script first.${NC}"
            sleep 3
            if [[ -f "packages/pkglist-debian.txt" ]]; then
                sudo apt-get update
                packages=$(sed 's/["'\'']//g' packages/pkglist-debian.txt | tr ' ' '\n' | grep -v -E '^\s*$|^#')
                for pkg in $packages; do
                    echo -e "${BLUE}Installing: $pkg${NC}"
                    sudo apt-get install -y "$pkg" || echo -e "${RED}Failed to install $pkg. Skipping...${NC}"
                done
            else
                echo -e "${RED}Warning: packages/pkglist-debian.txt not found!${NC}"
            fi
            ;;
            
        gentoo)
            if [[ -f "packages/pkglist-gentoo.txt" ]]; then
                packages=$(sed 's/["'\'']//g' packages/pkglist-gentoo.txt | tr ' ' '\n' | grep -v -E '^\s*$|^#')
                sudo emerge -av --noreplace $packages
            else
                echo -e "${RED}Warning: packages/pkglist-gentoo.txt not found!${NC}"
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
        GOPATH=$(go env GOPATH 2>/dev/null || echo "$HOME/go")
        export PATH="$GOPATH/bin:$PATH"

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
    local target_dir="$1"
    local source_dir="$2"

    if [[ -d "$target_dir" ]]; then
        if [[ -d "$source_dir" ]]; then
            if diff -rq "$target_dir" "$source_dir" >/dev/null 2>&1; then
                echo -e "${GREEN}$(basename "$target_dir") is already up-to-date. Skipping backup.${NC}"
                return 1
            fi
        fi

        local base_name=$(basename "$target_dir")
        local backup_name="${target_dir}_backup_$(date +%Y%m%d_%H%M%S)"
        echo -e "${BLUE}Modifications detected. Backing up existing $base_name to $(basename "$backup_name")${NC}"
        mv "$target_dir" "$backup_name"
    fi
    return 0
}

CONFIGS=(btop cava fastfetch hypr hypremoji kitty rofi swaync systemd wallpapers wallust waybar)

echo -e "${BLUE}Deploying configuration files...${NC}"
mkdir -p "$HOME/.config"

for conf in "${CONFIGS[@]}"; do
    backup_config "$HOME/.config/$conf" ".config/$conf"
    if [[ $? -eq 0 ]]; then
        if [[ -d ".config/$conf" ]]; then
            cp -r ".config/$conf" "$HOME/.config/" 2>/dev/null
            echo -e "  Copied new $conf config."
        else
            echo -e "${RED}  Warning: .config/$conf missing in source directory.${NC}"
        fi
    fi
done

echo -e "${BLUE}Finalizing directory structure...${NC}"
mkdir -p "$HOME/.config"

if [[ -d ".config" ]]; then
    cp -rv .config/* "$HOME/.config/" 2>/dev/null || echo -e "${RED}Warning: Some configs failed to copy.${NC}"
else
    echo -e "${RED}Error: .config directory not found in the source repository! Skipping configuration copy.${NC}"
fi

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
            
            monitor_name=$(echo "$name" | sed -E 's/^card[0-9]+-//')
            
            if [[ ! " ${MONITOR_LIST[*]} " =~ " ${monitor_name} " ]]; then
                MONITOR_LIST+=("$monitor_name")
            fi
        fi
    done
fi

MONITOR_COUNT=${#MONITOR_LIST[@]}

if [[ "$MONITOR_COUNT" -gt 0 ]]; then
    PRIMARY_MONITOR=${MONITOR_LIST[0]}
    SECONDARY_MONITOR=${MONITOR_LIST[1]:-$PRIMARY_MONITOR}

    echo -e "${GREEN}Detected $MONITOR_COUNT monitor(s). Primary: $PRIMARY_MONITOR${NC}"

    if [[ -d "$HOME/.config/hypr" ]]; then
        find "$HOME/.config/hypr" -type f -name "*.conf" -exec sed -i "s/__PRIMARY_MONITOR__/$PRIMARY_MONITOR/g" {} +
        
        if [[ "$MONITOR_COUNT" -ge 2 ]]; then
            echo -e "${GREEN}Secondary monitor detected: $SECONDARY_MONITOR${NC}"
            find "$HOME/.config/hypr" -type f -name "*.conf" -exec sed -i "s/__SECONDARY_MONITOR__/$SECONDARY_MONITOR/g" {} +
        else
            echo -e "${BLUE}Only one monitor detected. Commenting out secondary monitor lines...${NC}"
            find "$HOME/.config/hypr" -type f -name "*.conf" -exec sed -i '/monitor=__SECONDARY_MONITOR__/s/^/#/' {} +
        fi
    else
        echo -e "${RED}Error: $HOME/.config/hypr not found! The config copy likely failed.${NC}"
    fi
else
    echo -e "${RED}Warning: Could not automatically detect any monitors. Placeholders will remain unchanged.${NC}"
fi

SEARCH="/home/nekorosys"
REPLACE="$HOME"

echo -e "${BLUE}Replacing hardcoded paths... ($SEARCH -> $REPLACE)...${NC}"
find "$HOME/.config" -type d -name "*_backup_*" -prune -o -type f \( -name "*.config" -o -name "*.css" -o -name "*.rasi" -o -name "*.conf" -o -name "*.sh" -o -name "*.json" -o -name "*.jsonc" -o -name "*.lua" -o -name "*.py" -o -name "*.yaml" \) -print0 2>/dev/null | xargs -0 -r sed -i "s|$SEARCH|$REPLACE|g"

inject_shell_config() {
    local shell_rc="$1"
    local source_rc="$2"
    
    local go_bin_path
    if command -v go &> /dev/null; then
        go_bin_path="$(go env GOPATH 2>/dev/null || echo "$HOME/go")/bin"
    else
        go_bin_path="$HOME/go/bin"
    fi
    
    local export_bin_dir="${USER_BIN_DIR/$HOME/\$HOME}"

    if [[ -f "$shell_rc" ]]; then
        sed -i '/# --- NeKoRoSHELL START ---/,/# --- NeKoRoSHELL END ---/d' "$shell_rc"
        echo -e "\n# --- NeKoRoSHELL START ---" >> "$shell_rc"
        [[ -f "$source_rc" ]] && cat "$source_rc" >> "$shell_rc"
        echo "export PATH=\"$export_bin_dir:\$HOME/.cargo/bin:$go_bin_path:\$PATH\"" >> "$shell_rc"
        echo -e "# --- NeKoRoSHELL END ---" >> "$shell_rc"
        echo -e "${GREEN}Updated $shell_rc${NC}"
    fi
}

inject_shell_config "$HOME/.bashrc" ".bashrc"
inject_shell_config "$HOME/.zshrc" ".zshrc"

[[ -f .p10k.zsh ]] && cp .p10k.zsh "$HOME/"
[[ -f .face.icon ]] && cp .face.icon "$HOME/"
[[ -f change-avatar.sh ]] && cp change-avatar.sh "$HOME/"

if [[ -d bin ]]; then
    echo -e "${BLUE}Copying scripts to $USER_BIN_DIR...${NC}"
    mkdir -p "$USER_BIN_DIR"
    cp -r bin/* "$USER_BIN_DIR/" 2>/dev/null
fi

# ==============================================================================
# DOWNLOADING & COMPILING (Compilation Mode Only)
# ==============================================================================

if [[ "$INSTALL_TYPE" == "compilation" ]]; then
    if ! command -v hyprshot &> /dev/null; then
        echo -e "${BLUE}Downloading hyprshot...${NC}"
        mkdir -p "$USER_BIN_DIR"
        curl -sLo "$USER_BIN_DIR/hyprshot" https://raw.githubusercontent.com/Gustash/Hyprshot/main/hyprshot
        chmod +x "$USER_BIN_DIR/hyprshot"
    fi

    if [[ ! -d "$HOME/powerlevel10k" ]]; then
        echo -e "${BLUE}Cloning Powerlevel10k theme...${NC}"
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"
    fi

    if ! command -v g++ &> /dev/null; then
        echo -e "${RED}g++ is not installed. Please install build tools (e.g., build-essential or base-devel) to compile the C++ daemons.${NC}"
    elif ! command -v pkg-config &> /dev/null; then
        echo -e "${RED}pkg-config is not installed. Cannot verify C++ header dependencies.${NC}"
    else
        echo -e "${BLUE}Checking C++ build dependencies...${NC}"
        
        REQUIRED_LIBS="wayland-client" 
        
        if ! pkg-config --exists $REQUIRED_LIBS; then
            echo -e "${RED}Missing required C++ development headers: $REQUIRED_LIBS${NC}"
            echo -e "${RED}Please install the corresponding -dev / -devel packages. Compilation aborted.${NC}"
        else
            echo -e "${BLUE}Compiling C++ Daemons...${NC}"
            mkdir -p "$USER_BIN_DIR"
            
            LIBS=$(pkg-config --cflags --libs $REQUIRED_LIBS)
            
            if [[ -f "bin/source/navbar-hover.cpp" ]]; then
                g++ -O3 -o "$USER_BIN_DIR/navbar-hover" bin/source/navbar-hover.cpp $LIBS
                echo -e "${GREEN}Successfully compiled navbar-hover.${NC}"
            else
                echo -e "${RED}Warning: bin/source/navbar-hover.cpp not found.${NC}"
            fi
            
            if [[ -f "bin/source/navbar-watcher.cpp" ]]; then
                g++ -O3 -o "$USER_BIN_DIR/navbar-watcher" bin/source/navbar-watcher.cpp $LIBS
                echo -e "${GREEN}Successfully compiled navbar-watcher.${NC}"
            else
                echo -e "${RED}Warning: bin/source/navbar-watcher.cpp not found.${NC}"
            fi
        fi
    fi
fi

# ==============================================================================
# PERMISSIONS & SERVICES (Both Minimal & Compilation)
# ==============================================================================

echo -e "${BLUE}Setting script permissions...${NC}"
find "$HOME/.config/" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null
if [[ -d "$USER_BIN_DIR" ]]; then
    find "$USER_BIN_DIR/" -type f -exec chmod +x {} + 2>/dev/null
fi

if command -v systemctl >/dev/null 2>&1; then
    echo -e "${BLUE}Enabling Wayland services...${NC}"
    systemctl --user daemon-reload
    systemctl --user enable waybar.service 2>/dev/null
    systemctl --user enable swaync.service 2>/dev/null
else
    echo -e "${RED}Cannot run systemctl. Please enable waybar and SwayNC manually.${NC}"
fi

# ==============================================================================
# FINAL VERIFICATION
# ==============================================================================

echo -e "\n${BLUE}Performing final system check...${NC}"
CORE_CMDS=("hyprland" "btop" "cava" "fastfetch" "hypremoji" "waybar" "swaync" "rofi" "kitty" "wallust" "swww")
MISSING=0

for cmd in "${CORE_CMDS[@]}"; do
    if command -v "$cmd" &> /dev/null; then
        echo -e "  [${GREEN}OK${NC}] $cmd is installed."
    else
        echo -e "  [${RED}!!${NC}] $cmd is missing from PATH."
        MISSING=$((MISSING + 1))
    fi
done

if [[ "$MISSING" -eq 0 ]]; then
    echo -e "\n${GREEN}Everything looks good! NeKoRoSHELL is ready.${NC}"
else
    echo -e "\n${RED}Warning: $MISSING core component(s) were not found.${NC}"
    echo -e "If you chose 'Minimal', this is expected. Otherwise, check the logs above."
fi

echo -e "${GREEN}Installation complete! Please restart your session to apply all changes.${NC}"
