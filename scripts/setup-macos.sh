#!/bin/bash
set -euo pipefail

# macOS-specific setup.
#
# Everything portable lives in the shared configs under .config/, so this script
# only covers what genuinely cannot be shared across operating systems: the GUI
# terminal, the Nerd Font, and registering Fish as the login shell.

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

require_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        return 0
    fi
    log_error "Homebrew is required for the GUI terminal and the Nerd Font."
    log_error "Install it from https://brew.sh and re-run this script."
    exit 1
}

# Ghostty and the font ship as casks. nixpkgs has no usable darwin build of
# either, so Homebrew owns the GUI layer even on a Nix-first machine.
install_gui() {
    if [ -d "/Applications/Ghostty.app" ]; then
        log_success "Ghostty already installed"
    else
        log_info "Installing Ghostty..."
        brew install --cask ghostty
    fi

    # Check the font directories rather than Homebrew: macOS does not scan the
    # Nix profile's font path, so a nix-installed Nerd Font is invisible here and
    # the cask (which installs into ~/Library/Fonts) is what actually works.
    if compgen -G "$HOME/Library/Fonts/JetBrainsMonoNerdFont*" >/dev/null ||
       compgen -G "/Library/Fonts/JetBrainsMonoNerdFont*" >/dev/null; then
        log_success "JetBrainsMono Nerd Font already installed"
    else
        log_info "Installing JetBrainsMono Nerd Font..."
        brew install --cask font-jetbrains-mono-nerd-font
    fi
}

# Fish usually comes from the Nix profile; only fall back to Homebrew.
ensure_fish() {
    if command -v fish >/dev/null 2>&1; then
        log_success "Fish available at $(command -v fish)"
        return 0
    fi
    log_info "Installing Fish..."
    brew install fish
}

# Ghostty's `command =` setting covers tabs Ghostty itself opens, but anything
# that spawns $SHELL or the passwd shell instead -- login, a tmux server started
# outside Ghostty, Calyx session tabs -- still lands in the old shell until the
# account's login shell is changed.
set_login_shell() {
    local fish_path
    fish_path="$(command -v fish)"

    if [ "$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')" = "$fish_path" ]; then
        log_success "Login shell is already $fish_path"
        return 0
    fi

    # chsh rejects any shell that is not listed in /etc/shells.
    if ! grep -qxF "$fish_path" /etc/shells; then
        log_info "Adding $fish_path to /etc/shells (needs sudo)"
        echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
    fi

    log_info "Changing the login shell to $fish_path (asks for your password)"
    chsh -s "$fish_path"
    log_success "Login shell set to $fish_path"
}

install_fish_plugins() {
    if [ -x "$SCRIPT_DIR/install-plugins.sh" ]; then
        "$SCRIPT_DIR/install-plugins.sh"
    else
        log_warning "Plugin installer not found at $SCRIPT_DIR/install-plugins.sh"
    fi
}

main() {
    log_info "Setting up the macOS-specific layer..."
    require_homebrew
    install_gui
    ensure_fish
    set_login_shell
    install_fish_plugins

    log_success "macOS setup complete"
    echo
    log_info "Next: launch Ghostty, then run ./scripts/verify-config.sh"
}

main "$@"
