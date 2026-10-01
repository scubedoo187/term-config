#!/bin/bash
set -e

# Cross-platform terminal setup installer
# Nix-first approach for macOS/Linux
# This script installs Nix and configures dotfiles

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# Check if Nix is already installed
check_nix_installed() {
    if command -v nix &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Install Nix
install_nix() {
    log_info "Installing Nix..."
    
    if check_nix_installed; then
        log_success "Nix is already installed"
        return 0
    fi
    
    # Download and run Nix installer
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
        sh -s -- install --no-confirm
    
    # Source Nix into current shell immediately
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
    
    log_success "Nix installed successfully"
}

# Enable flakes
enable_flakes() {
    log_info "Enabling Nix flakes..."
    
    local nix_conf="$HOME/.config/nix/nix.conf"
    mkdir -p "$(dirname "$nix_conf")"
    
    if ! grep -q "experimental-features" "$nix_conf" 2>/dev/null; then
        echo "experimental-features = nix-command flakes" >> "$nix_conf"
        log_success "Flakes enabled"
    else
        log_success "Flakes already enabled"
    fi
}

# Setup dotfiles
setup_dotfiles() {
    log_info "Setting up dotfiles..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    local config_dir="$HOME/.config"
    
    # Create ~/.config if it doesn't exist
    mkdir -p "$config_dir"
    
    # Create symlinks
    log_info "Creating symlinks..."
    
    # Ghostty config
    if [ -d "$config_dir/ghostty" ] || [ -L "$config_dir/ghostty" ]; then
        log_warning "Backing up existing ~/.config/ghostty"
        mv "$config_dir/ghostty" "$config_dir/ghostty.backup.$(date +%s)"
    fi
    ln -sfn "$script_dir/.config/ghostty" "$config_dir/ghostty"
    log_success "Linked Ghostty config"

    # Fish config
    if [ -d "$config_dir/fish" ] || [ -L "$config_dir/fish" ]; then
        log_warning "Backing up existing ~/.config/fish"
        mv "$config_dir/fish" "$config_dir/fish.backup.$(date +%s)"
    fi
    ln -sf "$script_dir/.config/fish" "$config_dir/fish"
    log_success "Linked Fish config to ~/.config/fish"

    # tmux config
    if [ -d "$config_dir/tmux" ] || [ -L "$config_dir/tmux" ]; then
        log_warning "Backing up existing ~/.config/tmux"
        mv "$config_dir/tmux" "$config_dir/tmux.backup.$(date +%s)"
    fi
    ln -sf "$script_dir/.config/tmux" "$config_dir/tmux"
    log_success "Linked tmux config"
    
    # Starship config
    if [ -f "$config_dir/starship.toml" ] || [ -L "$config_dir/starship.toml" ]; then
        log_warning "Backing up existing ~/.config/starship.toml"
        mv "$config_dir/starship.toml" "$config_dir/starship.toml.backup.$(date +%s)"
    fi
    ln -sf "$script_dir/.config/starship.toml" "$config_dir/starship.toml"
    log_success "Linked Starship config"

    # Ghostty on macOS reads this path before the XDG one, so a stale copy here
    # silently wins over the tracked config.
    local ghostty_appsupport="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
    if [ -f "$ghostty_appsupport" ] && [ ! -L "$ghostty_appsupport" ]; then
        log_warning "Backing up Ghostty's app-support config so the XDG dotfile wins"
        mv "$ghostty_appsupport" "$ghostty_appsupport.backup.$(date +%s)"
    fi
}

# Install packages via Nix
install_packages() {
    log_info "Installing packages via Nix..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    
    # Add Nix to current shell
    if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
        source "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    elif [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
        source "$HOME/.nix-profile/etc/profile.d/nix.sh"
    fi
    
    # Use Nix flake to install packages
    cd "$script_dir"
    
    log_info "Using 'nix profile install' for packages..."
    nix profile install ".#default" || {
        log_warning "nix profile install failed, trying home-manager..."
        
        # Try Home Manager if available
        if command -v home-manager &> /dev/null; then
            log_info "Using home-manager to apply configuration..."
            os_type=$(detect_os)
            
            case "$os_type" in
                macos)
                    home-manager switch --flake ".#user@macos"
                    ;;
                linux)
                    home-manager switch --flake ".#user@linux"
                    ;;
            esac
            log_success "Home Manager applied"
        else
            log_warning "Installing Home Manager first..."
            nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
            nix-channel --update
            nix-shell '<home-manager>' -A install
            
            os_type=$(detect_os)
            case "$os_type" in
                macos)
                    home-manager switch --flake ".#user@macos"
                    ;;
                linux)
                    home-manager switch --flake ".#user@linux"
                    ;;
            esac
            log_success "Home Manager installed and applied"
        fi
        return
    }
    
    log_success "Packages installed successfully"
}

# Main installation flow
main() {
    log_info "Cross-platform terminal setup installer"
    log_info "OS: $(detect_os)"
    echo
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    # Step 1: Install Nix
    install_nix
    
    # Step 2: Enable flakes
    enable_flakes
    
    # Step 3: Setup dotfiles
    setup_dotfiles
    
    # Step 4: Install packages
    install_packages

    # Step 5: Install Fish plugins
    log_info "Installing Fish plugins..."
    if [ -x "$script_dir/scripts/install-plugins.sh" ]; then
        "$script_dir/scripts/install-plugins.sh"
    else
        log_warning "Plugin installer not found at $script_dir/scripts/install-plugins.sh"
    fi
    
    echo
    log_success "✨ Installation complete!"
    echo
    log_info "Next steps:"
    echo "  1. Reload your shell (or source ~/.nix-profile/etc/profile.d/nix.sh)"
    echo "  2. Install the Ghostty GUI and set Fish as the login shell:"
    case "$(detect_os)" in
        macos) echo "       ./scripts/setup-macos.sh" ;;
        linux) echo "       ./scripts/setup-linux.sh" ;;
        *)     echo "       ./scripts/setup-macos.sh  (or setup-linux.sh)" ;;
    esac
    echo "  3. Register this checkout's git filters: ./scripts/setup-git-filters.sh"
    echo "  4. Launch Ghostty - it should open Fish with a Starship prompt and"
    echo "     auto-attach the tmux session named 'main'"
    echo "  5. Verify everything: ./scripts/verify-config.sh"
    echo
    log_warning "Note: You may need to restart your terminal or run:"
    echo "  source ~/.nix-profile/etc/profile.d/nix.sh"
}

main "$@"
