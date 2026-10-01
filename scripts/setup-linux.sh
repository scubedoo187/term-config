#!/bin/bash
set -euo pipefail

# Linux-specific setup.
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

detect_pkg_manager() {
    for candidate in pacman dnf zypper apt-get; do
        if command -v "$candidate" >/dev/null 2>&1; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

# Ghostty is packaged inconsistently across distros: Arch has it in the official
# repos, Fedora needs a COPR, and Debian/Ubuntu have no package at all. Rather
# than guess wrong, install it where that is unambiguous and otherwise point at
# the upstream instructions.
install_gui() {
    if command -v ghostty >/dev/null 2>&1; then
        log_success "Ghostty already installed"
        return 0
    fi

    case "$1" in
        pacman)
            log_info "Installing Ghostty via pacman..."
            sudo pacman -S --needed --noconfirm ghostty
            ;;
        *)
            log_warning "No reliable Ghostty package for this distro."
            log_warning "Install it from https://ghostty.org/docs/install, then re-run."
            ;;
    esac
}

install_font() {
    local font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
    if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
        log_success "JetBrainsMono Nerd Font already installed"
        return 0
    fi

    log_info "Installing JetBrainsMono Nerd Font into $font_dir"
    mkdir -p "$font_dir"
    local tmp
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' RETURN
    curl -fsSL -o "$tmp/JetBrainsMono.zip" \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
    unzip -oq "$tmp/JetBrainsMono.zip" -d "$font_dir"
    fc-cache -f "$font_dir" >/dev/null
    log_success "Font installed"
}

# Fish usually comes from the Nix profile; only fall back to the distro package.
ensure_fish() {
    if command -v fish >/dev/null 2>&1; then
        log_success "Fish available at $(command -v fish)"
        return 0
    fi

    log_info "Installing Fish..."
    case "$1" in
        pacman)  sudo pacman -S --needed --noconfirm fish ;;
        dnf)     sudo dnf install -y fish ;;
        zypper)  sudo zypper install -y fish ;;
        apt-get) sudo apt-get update && sudo apt-get install -y fish ;;
    esac
}

# The terminal's own `command =` setting covers tabs it opens itself, but
# anything that spawns $SHELL or the passwd shell instead -- login, a tmux server
# started outside the GUI, SSH -- still lands in the old shell until the
# account's login shell is changed.
set_login_shell() {
    local fish_path
    fish_path="$(command -v fish)"

    if [ "$(getent passwd "$USER" | cut -d: -f7)" = "$fish_path" ]; then
        log_success "Login shell is already $fish_path"
        return 0
    fi

    # chsh rejects any shell that is not listed in /etc/shells.
    if ! grep -qxF "$fish_path" /etc/shells; then
        log_info "Adding $fish_path to /etc/shells (needs sudo)"
        echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
    fi

    log_info "Changing the login shell to $fish_path"
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
    log_info "Setting up the Linux-specific layer..."

    local pkg
    if ! pkg="$(detect_pkg_manager)"; then
        log_error "No supported package manager found (pacman/dnf/zypper/apt-get)"
        exit 1
    fi
    log_info "Package manager: $pkg"

    install_gui "$pkg"
    install_font
    ensure_fish "$pkg"
    set_login_shell
    install_fish_plugins

    log_success "Linux setup complete"
    echo
    log_info "Next: launch Ghostty, then run ./scripts/verify-config.sh"
}

main "$@"
