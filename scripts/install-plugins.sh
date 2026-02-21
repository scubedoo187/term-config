#!/bin/bash

# install-plugins.sh - Install Fish plugins using Fisher
# Reads plugins from ~/.config/fish/fish_plugins

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Ensure Fish config directory exists
FISH_CONFIG_DIR="$HOME/.config/fish"
FISH_PLUGINS_FILE="$FISH_CONFIG_DIR/fish_plugins"

if [ ! -f "$FISH_PLUGINS_FILE" ]; then
    echo "Error: $FISH_PLUGINS_FILE not found."
    exit 1
fi

# Check if fish is installed
if ! command -v fish &> /dev/null; then
    echo "Error: fish is not installed."
    exit 1
fi

log_info "Installing Fish plugins..."

# Install Fisher if not present
# We run this inside fish to ensure proper function installation
fish -c "
    if not type -q fisher
        echo 'Fisher not found. Installing...'
        curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
    end
"

# Update/Install plugins from fish_plugins file
# 'fisher update' automatically reads from the fish_plugins file if it exists
log_info "Running fisher update..."
fish -c "fisher update"

log_success "Plugins installed successfully!"
