#!/bin/bash

# setup-linux.sh - Linux-specific setup for WezTerm multiplexer and session management
# Uses systemd user units for persistent mux-server
# All paths are dynamically detected - no hardcoded user/machine-specific values

set -e

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

detect_wezterm_mux() {
    WEZTERM_MUX_SERVER="$(command -v wezterm-mux-server 2>/dev/null || true)"
    
    if [ -z "$WEZTERM_MUX_SERVER" ]; then
        for candidate in \
            "/usr/bin/wezterm-mux-server" \
            "/usr/local/bin/wezterm-mux-server" \
            "$HOME/.nix-profile/bin/wezterm-mux-server" \
            "$HOME/.local/bin/wezterm-mux-server"
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

generate_service() {
    local service_path="$1"
    
    cat > "$service_path" <<EOF
[Unit]
Description=WezTerm Mux Server
Documentation=https://wezfurlong.org/wezterm/
After=default.target

[Service]
Type=simple
ExecStart=${WEZTERM_MUX_SERVER}
Restart=always
RestartSec=5
Environment=XDG_RUNTIME_DIR=%t
Environment=XDG_DATA_HOME=${XDG_DATA_HOME}

[Install]
WantedBy=default.target
EOF
}

main() {
    log_info "🚀 Setting up WezTerm for Linux..."

    detect_wezterm_mux

    XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
    WEZTERM_DATA_DIR="$XDG_DATA_HOME/wezterm"
    mkdir -p "$WEZTERM_DATA_DIR"
    log_info "Data directory: $WEZTERM_DATA_DIR"

    SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
    mkdir -p "$SYSTEMD_USER_DIR"

    SERVICE_FILE="$SYSTEMD_USER_DIR/wezterm-mux-server.service"

    if systemctl --user is-active wezterm-mux-server > /dev/null 2>&1; then
        log_warning "Stopping existing wezterm-mux-server service..."
        systemctl --user stop wezterm-mux-server || true
    fi

    log_info "Generating systemd user service..."
    generate_service "$SERVICE_FILE"
    log_success "Generated service at $SERVICE_FILE"

    systemctl --user daemon-reload
    log_success "Reloaded systemd user daemon"

    systemctl --user enable wezterm-mux-server
    log_success "Enabled wezterm-mux-server service"

    systemctl --user start wezterm-mux-server
    log_success "Started wezterm-mux-server service"

    sleep 2
    if systemctl --user is-active wezterm-mux-server > /dev/null 2>&1; then
        log_success "✓ Mux-server service is active"
    else
        log_error "✗ Mux-server service failed to start"
        systemctl --user status wezterm-mux-server
        exit 1
    fi

    if pgrep -f "wezterm-mux-server" > /dev/null; then
        log_success "✓ Mux-server process is running"
    else
        log_warning "⚠ Mux-server process not detected yet"
    fi

    sleep 2
    if [ -S "$WEZTERM_DATA_DIR/sock" ]; then
        log_success "✓ Mux-server socket exists at $WEZTERM_DATA_DIR/sock"
    else
        log_warning "⚠ Socket not found yet - will be created on first GUI connection"
    fi

    log_success "✨ Linux setup complete!"
    echo
    log_info "Configuration summary:"
    echo "  • Binary:  $WEZTERM_MUX_SERVER"
    echo "  • Data:    $WEZTERM_DATA_DIR"
    echo "  • Service: $SERVICE_FILE"
    echo
    log_info "Useful commands:"
    echo "  • Status:  systemctl --user status wezterm-mux-server"
    echo "  • Logs:    journalctl --user -u wezterm-mux-server -f"
    echo "  • Restart: systemctl --user restart wezterm-mux-server"
}

main "$@"
