# Usage Guide

## Installation

### Prerequisites
- WezTerm installed
- Fish installed (recommended)
- Starship installed (recommended)

### Default Setup

The default path is local WezTerm persistence:

- WezTerm GUI connects to a local mux-server.
- Fish is the shell inside panes.
- `resurrect` is only a backup/manual restore layer.

```bash
cd ~/term-config
./scripts/verify-config.sh
```

### macOS

```bash
cd ~/term-config
./scripts/setup-macos.sh
```

This will:
1. Detect `wezterm-mux-server` binary location automatically
2. Generate launchd plist with correct paths
3. Register and start the mux-server service
4. Verify socket creation

**Verification:**
```bash
launchctl list | grep wezterm
ls -la ~/.local/share/wezterm/sock
```

### Linux

```bash
cd ~/term-config
./scripts/setup-linux.sh
```

This will:
1. Detect `wezterm-mux-server` binary location automatically
2. Generate systemd user service with correct paths
3. Enable and start the mux-server service
4. Verify socket creation

**Verification:**
```bash
systemctl --user status wezterm-mux-server
ls -la ~/.local/share/wezterm/sock
```

---

## Session Persistence Architecture

```
Layer 1: WezTerm mux-server (real-time)
├── Runs as a local daemon
├── GUI closes → sessions persist
├── New GUI → reconnects to the same local workspace
└── Socket: ~/.local/share/wezterm/sock

Layer 2: Resurrect (backup)
├── Manual save/restore for recovery
├── Periodic backup snapshots
└── Secondary safety net when mux state is insufficient
```

---

## Keybindings

**WezTerm Leader: `CTRL+A`**

### Pane Management
| Key | Action |
|-----|--------|
| `|` | Split horizontal |
| `-` | Split vertical |
| `c` | New tab |
| `n/p` | Next/previous tab |
| `z` | Toggle zoom |

### Workspaces / Restore
| Key | Action |
|-----|--------|
| `w` | New workspace |
| `s` | Workspace list |
| `a` | Workspace switcher |
| `A` | Previous workspace |
| `CTRL+S` | Save workspace state |
| `r` | Restore saved state |
| `x` | Delete saved state |

### WezTerm
| Key | Action |
|-----|--------|
| `CMD+SHIFT+C` | Copy |
| `CMD+SHIFT+V` | Paste |
| `ALT+L` | Show launcher |

### Fish/FZF Keybindings
| Key | Action |
|-----|--------|
| `CTRL+R` | History search (fzf) |
| `CTRL+T` | File finder (fzf) |
| `ALT+C` | Directory jump (fzf) |

## Troubleshooting

### Stale WezTerm state

```bash
./scripts/cleanup-wezterm-state.sh
```

This removes stale `agent.*`, `gui-sock-*`, and oversized local WezTerm logs after `wezterm-mux-server` has been stopped.

### Legacy mux-server not starting

**macOS:**
```bash
launchctl unload ~/Library/LaunchAgents/com.wezterm.mux-server.plist
launchctl load ~/Library/LaunchAgents/com.wezterm.mux-server.plist
tail -f ~/.local/share/wezterm/mux-server.log
```

**Linux:**
```bash
systemctl --user restart wezterm-mux-server
journalctl --user -u wezterm-mux-server -f
```

### Pi warning: tmux extended-keys is off

This setup no longer uses tmux as the primary persistence layer.

### Legacy socket not found

Wait a few seconds after starting mux-server, or launch WezTerm GUI once:
```bash
ls -la ~/.local/share/wezterm/sock
```

### Legacy GUI not connecting to mux-server

Verify mux-server is running:
```bash
pgrep -f wezterm-mux-server
```

Check WezTerm config connects to unix domain:
```lua
config.default_gui_startup_args = { "connect", "unix" }
```

## Uninstall Legacy mux-server

### macOS
```bash
launchctl unload ~/Library/LaunchAgents/com.wezterm.mux-server.plist
rm ~/Library/LaunchAgents/com.wezterm.mux-server.plist
```

### Linux
```bash
systemctl --user disable --now wezterm-mux-server
rm ~/.config/systemd/user/wezterm-mux-server.service
systemctl --user daemon-reload
```
