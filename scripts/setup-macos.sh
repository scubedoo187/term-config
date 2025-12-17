#!/bin/bash

# setup-macos.sh - macOS-specific setup for WezTerm multiplexer and session management
# This script sets up launchd agents for persistent mux-server and session handling

set -e

# Colors for output
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

main() {
    log_info "🚀 Setting up WezTerm for macOS..."

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
    LAUNCHAGENTS_DIR="$HOME/Library/LaunchAgents"

    # Create LaunchAgents directory if it doesn't exist
    mkdir -p "$LAUNCHAGENTS_DIR"

    # Setup mux-server launchd agent
    log_info "Setting up mux-server launchd agent..."

    PLIST_FILE="$SCRIPT_DIR/com.wezterm.mux-server.plist"
    LAUNCH_PLIST="$LAUNCHAGENTS_DIR/com.wezterm.mux-server.plist"

    if [ ! -f "$PLIST_FILE" ]; then
        log_error "Plist file not found: $PLIST_FILE"
        exit 1
    fi

    # Copy plist file
    cp "$PLIST_FILE" "$LAUNCH_PLIST"
    log_success "Copied plist to $LAUNCH_PLIST"

    # Load launchd agent
    if launchctl list | grep -q "com.wezterm.mux-server"; then
        log_warning "Unloading existing com.wezterm.mux-server agent..."
        launchctl unload "$LAUNCH_PLIST" || true
    fi

    launchctl load "$LAUNCH_PLIST"
    log_success "Loaded com.wezterm.mux-server agent"

    # Verify mux-server is running
    sleep 2
    if launchctl list | grep -q "com.wezterm.mux-server"; then
        log_success "✓ Mux-server agent is running"
    else
        log_error "✗ Mux-server agent failed to start"
        exit 1
    fi

    # Verify mux-server process
    if pgrep -f "wezterm-mux-server" > /dev/null; then
        log_success "✓ Mux-server process is active"
    else
        log_error "✗ Mux-server process is not running"
        exit 1
    fi

    # Verify socket exists
    if [ -S "$HOME/.local/share/wezterm/sock" ]; then
        log_success "✓ Mux-server socket exists"
    else
        log_error "✗ Mux-server socket not found"
        exit 1
    fi

    log_success "✨ macOS setup complete!"
    echo
    log_info "Next steps:"
    echo "• Close all WezTerm windows completely"
    echo "• Launch WezTerm - it should connect to mux-server automatically"
    echo "• Use 'wezterm cli list' to verify connection to multiplexer"
    echo "• Check logs: tail -f ~/.local/share/wezterm/mux-server.log"
}

main "$@"
