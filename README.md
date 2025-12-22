# term-config

Cross-platform terminal configuration for **WezTerm + Nushell + Starship**.

Unified terminal experience across macOS and Linux with persistent session management.

## Features

- **Nushell** as default shell with **Starship** prompt
- **Session persistence** via mux-server + resurrect plugin
- **Smart workspace switching** with auto-save/restore
- **Nix-first** installation (also supports Homebrew)
- Minimal UI: hidden tab bar, clean aesthetics

## Quick Start

```bash
# Clone
git clone https://github.com/scubedoo187/term-config.git ~/term-config

# Symlink configs
ln -sf ~/term-config/.config/wezterm ~/.config/wezterm
ln -sf ~/term-config/.config/nushell ~/.config/nushell
ln -sf ~/term-config/.config/starship.toml ~/.config/starship.toml
ln -sf ~/term-config/.config/wezterm/wezterm.lua ~/.wezterm.lua

# Install (Nix)
nix profile install .

# Or install (Homebrew)
brew install wezterm nushell starship
```

## Keybindings

**Leader: `Ctrl+A`**

| Key | Action |
|-----|--------|
| `h/j/k/l` | Navigate panes |
| `\` | Split horizontal |
| `-` | Split vertical |
| `c` | New tab |
| `p/n` | Prev/next tab |
| `s` | Workspace switcher |
| `a` | Previous workspace |
| `w` | New workspace |
| `z` | Zoom pane |
| `Ctrl+s` | Save session |
| `r` | Restore session |
| `x` | Delete session |

## Session Persistence

Sessions persist across GUI restarts via WezTerm mux-server.

```bash
# macOS: Setup mux-server (one-time)
./scripts/setup-macos.sh
```

Workspaces auto-save on switch. After reboot, use `Leader+s` to restore.

## Structure

```
.config/
  wezterm/
    wezterm.lua          # Main config
    modules/
      appearance.lua     # Theme, fonts
      keybindings.lua    # Key mappings
      mux-domain.lua     # Mux-server config
      resurrect.lua      # Session persistence
  nushell/
    config.nu            # Shell config
    env.nu               # Environment
  starship.toml          # Prompt config
```

## Requirements

- WezTerm
- Nushell
- Starship
- JetBrainsMono Nerd Font

## License

MIT
