#!/bin/bash

# setup-macos.sh - macOS-specific setup for WezTerm multiplexer and session management
# This script sets up launchd agents for persistent mux-server and session handling
# All paths are dynamically detected - no hardcoded user/machine-specific values

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

# Detect wezterm-mux-server binary location
detect_wezterm_mux() {
    # Try PATH first
    WEZTERM_MUX_SERVER="$(command -v wezterm-mux-server 2>/dev/null || true)"
    
    # If not found in PATH, check common installation locations
    if [ -z "$WEZTERM_MUX_SERVER" ]; then
        for candidate in \
            "/Applications/WezTerm.app/Contents/MacOS/wezterm-mux-server" \
            "/usr/local/bin/wezterm-mux-server" \
            "/opt/homebrew/bin/wezterm-mux-server" \
            "$HOME/.nix-profile/bin/wezterm-mux-server"
        do
            if [ -x "$candidate" ]; then
                WEZTERM_MUX_SERVER="$candidate"
                break
            fi
        done
    fi
    
    if [ -z "$WEZTERM_MUX_SERVER" ]; then
        log_error "wezterm-mux-server not found in PATH or known locations"
        log_error "Please install WezTerm first: https://wezfurlong.org/wezterm/install/"
        exit 1
    fi
    
    log_info "Detected wezterm-mux-server: $WEZTERM_MUX_SERVER"
}

# Generate plist dynamically with detected paths
generate_plist() {
    local plist_path="$1"
    
    cat > "$plist_path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.wezterm.mux-server</string>
    <key>ProgramArguments</key>
    <array>
        <string>${WEZTERM_MUX_SERVER}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${WEZTERM_DATA_DIR}/mux-server.log</string>
    <key>StandardErrorPath</key>
    <string>${WEZTERM_DATA_DIR}/mux-server-error.log</string>
    <key>WorkingDirectory</key>
    <string>${HOME}</string>
</dict>
</plist>
EOF
}

main() {
    log_info "🚀 Setting up WezTerm for macOS..."

    # Detect wezterm-mux-server binary
    detect_wezterm_mux

    # Setup XDG-compliant data directory
    XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
    WEZTERM_DATA_DIR="$XDG_DATA_HOME/wezterm"
    mkdir -p "$WEZTERM_DATA_DIR"
    log_info "Data directory: $WEZTERM_DATA_DIR"

    # Setup LaunchAgents directory
    LAUNCHAGENTS_DIR="$HOME/Library/LaunchAgents"
    mkdir -p "$LAUNCHAGENTS_DIR"

    LAUNCH_PLIST="$LAUNCHAGENTS_DIR/com.wezterm.mux-server.plist"

    # Unload existing agent if present
    if launchctl list 2>/dev/null | grep -q "com.wezterm.mux-server"; then
        log_warning "Unloading existing com.wezterm.mux-server agent..."
        launchctl unload "$LAUNCH_PLIST" 2>/dev/null || true
        sleep 1
    fi

    # Generate plist with dynamic paths
    log_info "Generating launchd plist with detected paths..."
    generate_plist "$LAUNCH_PLIST"
    log_success "Generated plist at $LAUNCH_PLIST"

    # Validate plist syntax
    if ! plutil -lint "$LAUNCH_PLIST" > /dev/null 2>&1; then
        log_error "Generated plist has syntax errors"
        plutil -lint "$LAUNCH_PLIST"
        exit 1
    fi
    log_success "Plist syntax validated"

    # Load launchd agent
    launchctl load "$LAUNCH_PLIST"
    log_success "Loaded com.wezterm.mux-server agent"

    # Verify mux-server is running
    sleep 2
    if launchctl list 2>/dev/null | grep -q "com.wezterm.mux-server"; then
        log_success "✓ Mux-server agent is registered"
    else
        log_error "✗ Mux-server agent failed to register"
        exit 1
    fi

    # Verify mux-server process
    if pgrep -f "wezterm-mux-server" > /dev/null; then
        log_success "✓ Mux-server process is active"
    else
        log_warning "⚠ Mux-server process not detected yet (may take a moment)"
    fi

    # Verify socket exists (may take a moment)
    sleep 2
    if [ -S "$WEZTERM_DATA_DIR/sock" ]; then
        log_success "✓ Mux-server socket exists at $WEZTERM_DATA_DIR/sock"
    else
        log_warning "⚠ Socket not found yet - will be created on first GUI connection"
    fi

    log_success "✨ macOS setup complete!"
    echo
    log_info "Configuration summary:"
    echo "  • Binary: $WEZTERM_MUX_SERVER"
    echo "  • Data:   $WEZTERM_DATA_DIR"
    echo "  • Plist:  $LAUNCH_PLIST"
    echo
    log_info "Next steps:"
    echo "  • Close all WezTerm windows completely"
    echo "  • Launch WezTerm - it should connect to mux-server automatically"
    echo "  • Use 'wezterm cli list' to verify connection to multiplexer"
    echo "  • Check logs: tail -f $WEZTERM_DATA_DIR/mux-server.log"
}

main "$@"
