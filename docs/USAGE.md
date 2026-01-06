# Usage Guide

## Installation

### Prerequisites
- WezTerm installed
- Fish installed (recommended)
- Starship installed (recommended)

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
Layer 1: Mux-Server (real-time)
├── Runs as background daemon (launchd/systemd)
├── GUI closes → sessions persist
├── New GUI → reconnects instantly
└── Socket: ~/.local/share/wezterm/sock

Layer 2: Resurrect Plugin (backup)
├── Auto-saves every 15 minutes
├── Manual save/restore available
├── Survives system reboot/crash
└── Storage: ~/.local/share/wezterm/resurrect/
```

---

## Keybindings

**Leader Key: `CTRL+A`**

### Navigation
| Key | Action |
|-----|--------|
| `h` | Move to left pane |
| `j` | Move to down pane |
| `k` | Move to up pane |
| `l` | Move to right pane |

### Pane Management
| Key | Action |
|-----|--------|
| `\` | Split horizontal |
| `-` | Split vertical |
| `z` | Toggle zoom |
| `CMD+W` | Close pane |

### Pane Resize
| Key | Action |
|-----|--------|
| `CTRL+CMD+H` | Resize left |
| `CTRL+CMD+J` | Resize down |
| `CTRL+CMD+K` | Resize up |
| `CTRL+CMD+L` | Resize right |

### Tabs
| Key | Action |
|-----|--------|
| `c` | New tab |
| `p` | Previous tab |
| `n` | Next tab |
| `,` | Rename tab |

### Workspaces
| Key | Action |
|-----|--------|
| `w` | New workspace |
| `s` | Workspace launcher (fuzzy) |
| `.` | Rename workspace |

### Launchers
| Key | Action |
|-----|--------|
| `t` | Tab launcher (fuzzy) |
| `m` | Domain launcher (fuzzy) |
| `ALT+L` | Show launcher |

### Multiplexer
| Key | Action |
|-----|--------|
| `d` | Attach to local domain |
| `SHIFT+D` | Detach from domain |

### Session (Resurrect)
| Key | Action |
|-----|--------|
| `S` | Save current state |
| `R` | Restore state (fuzzy) |
| `ALT+D` | Delete saved state (fuzzy) |

### Fish/FZF Keybindings
| Key | Action |
|-----|--------|
| `CTRL+R` | History search (fzf) |
| `CTRL+T` | File finder (fzf) |
| `ALT+C` | Directory jump (fzf) |

### Other
| Key | Action |
|-----|--------|
| `[` | Enter copy mode |
| `CTRL+A, CTRL+A` | Send CTRL+A |

---

## Troubleshooting

### Mux-server not starting

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

### Socket not found

Wait a few seconds after starting mux-server, or launch WezTerm GUI once:
```bash
ls -la ~/.local/share/wezterm/sock
```

### GUI not connecting to mux-server

Verify mux-server is running:
```bash
pgrep -f wezterm-mux-server
```

Check WezTerm config connects to unix domain:
```lua
config.default_gui_startup_args = { "connect", "unix" }
```

### Resurrect not saving/restoring

Check resurrect plugin is loaded:
```bash
ls ~/.local/share/wezterm/plugins/
ls ~/.local/share/wezterm/resurrect/
```

---

## Uninstall

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
