# term-config

Cross-platform terminal configuration for **WezTerm + Fish + Starship**.

Unified terminal experience across macOS and Linux with **WezTerm mux-server** as the local session persistence layer.

## Features

- **Fish** as default shell with **Starship** prompt
- **WezTerm mux-server** for local session persistence
- **Fish** as default shell with **Starship** prompt
- **Nix-first** installation (also supports Homebrew)
- Minimal UI: hidden tab bar, clean aesthetics

## Quick Start

```bash
# Clone
git clone https://github.com/scubedoo187/term-config.git ~/term-config

# Symlink configs
ln -sf ~/term-config/.config/wezterm ~/.config/wezterm
ln -sf ~/term-config/.config/fish ~/.config/fish
ln -sf ~/term-config/.config/starship.toml ~/.config/starship.toml
ln -sf ~/term-config/.config/wezterm/wezterm.lua ~/.wezterm.lua

# Install (Nix)
nix profile install .

# Or install (Homebrew)
brew install wezterm fish starship
```

## Keybindings

## Session Model

- WezTerm GUI connects to a local `wezterm-mux-server`.
- GUI restarts do not destroy panes/tabs/workspaces.
- `resurrect` is a backup/manual restore layer, not the primary persistence mechanism.

## Keybindings

**WezTerm Leader: `Ctrl+A`**

| Key | Action |
|-----|--------|
| `Ctrl+A c` | New tab |
| `Ctrl+A n/p` | Next/previous tab |
| `Ctrl+A |` | Split horizontal |
| `Ctrl+A -` | Split vertical |
| `Ctrl+A w` | New workspace |
| `Ctrl+A s` | Workspace list |
| `Ctrl+A a` | Workspace switcher |
| `Ctrl+A Ctrl+S` | Save workspace state |
| `Ctrl+A r` | Restore saved state |

**WezTerm**

| Key | Action |
|-----|--------|
| `Cmd+Shift+C` | Copy |
| `Cmd+Shift+V` | Paste |
| `Alt+L` | Launcher |

**Fish/FZF Keybindings**

| Key | Action |
|-----|--------|
| `Ctrl+R` | History search (fzf) |
| `Ctrl+T` | File finder (fzf) |
| `Alt+C` | Directory jump (fzf) |

## Maintenance

```bash
./scripts/verify-config.sh
./scripts/cleanup-wezterm-state.sh
./scripts/check-wezterm-mux-health.sh
```

The cleanup script is for stale local WezTerm state only. It refuses to run while `wezterm-mux-server` is active.

## Structure

```
.config/
  wezterm/
    wezterm.lua          # Main config
    modules/
      appearance.lua     # Theme, fonts
      keybindings.lua    # Minimal GUI key mappings
  fish/
    config.fish          # Shell config
    conf.d/
      env.fish           # Environment
      aliases.fish       # Aliases
  starship.toml          # Prompt config
```

## Requirements

- WezTerm
- Fish
- Starship
- JetBrainsMono Nerd Font

## License

MIT
