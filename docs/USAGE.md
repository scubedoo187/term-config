# Usage Guide

## Default Setup

The default workflow is tmux-first persistence:

```text
Ghostty / WezTerm = GUI renderer
Fish             = login shell and shared UX
Starship         = prompt
tmux             = sessions, panes, windows, persistence
```

Ghostty is preferred on macOS. WezTerm is kept available, but native WezTerm mux/workspace persistence is disabled in the active config.

```bash
cd ~/term-config
./scripts/verify-config.sh
```

## Ghostty

Config path:

```text
~/.config/ghostty/config -> ~/term-config/.config/ghostty/config
```

If Ghostty generated this fallback file earlier, remove it so the XDG dotfile stays authoritative:

```text
~/Library/Application Support/com.mitchellh.ghostty/config
```

Important settings:

```ini
command = /opt/homebrew/bin/fish --login --interactive
term = xterm-256color
font-family = JetBrainsMono Nerd Font Mono
theme = Seoulbones Dark
scrollback-limit = 100000
```

`term = xterm-256color` intentionally avoids tmux/ncurses warnings such as:

```text
missing or unsuitable terminal: xterm-ghostty
```

Validate:

```bash
ghostty +validate-config --config-file ~/.config/ghostty/config
ghostty +show-config | rg '^(command|term|font-family|theme|scrollback-limit)'
```

## Fish auto tmux attach

For local GUI terminals, Fish auto-attaches to tmux session `main`:

```bash
tmux attach-session -t main || tmux new-session -s main
```

Auto attach is skipped when:

- already inside tmux
- running over SSH
- `DISABLE_AUTO_TMUX` is set
- tmux is unavailable

One-off bypass:

```bash
DISABLE_AUTO_TMUX=1 fish
```

## tmux

`Ctrl+A` belongs to tmux. GUI terminals should not intercept it.

Useful commands:

```bash
tmux ls
tmux attach -t main
tmux new -s main
tmux detach
```

The config enables extended keys for Pi/Codex compatibility:

```tmux
set -g extended-keys on
```

Verify:

```bash
tmux show-options -g extended-keys
```

Expected:

```text
extended-keys on
```

## Keybindings

### tmux

Use tmux for pane/window/session management via `Ctrl+A` prefix.

### GUI terminal

| Key | Action |
|-----|--------|
| `CMD+SHIFT+C` | Copy |
| `CMD+SHIFT+V` | Paste |
| `ALT+L` | WezTerm launcher |

### Fish/FZF

| Key | Action |
|-----|--------|
| `CTRL+R` | History search |
| `CTRL+T` | File finder |
| `ALT+C` | Directory jump |

## Legacy WezTerm mux notes

WezTerm native mux-server/resurrect/workspace-history files may still exist in the repo for reference, but they are not loaded by the active `wezterm.lua`.

If stale WezTerm mux state causes problems after migration:

```bash
./scripts/check-wezterm-mux-health.sh
./scripts/cleanup-wezterm-state.sh
```

Stop old launch agents/services if needed:

### macOS

```bash
launchctl unload ~/Library/LaunchAgents/com.wezterm.mux-server.plist 2>/dev/null || true
rm -f ~/Library/LaunchAgents/com.wezterm.mux-server.plist
```

### Linux

```bash
systemctl --user disable --now wezterm-mux-server 2>/dev/null || true
rm -f ~/.config/systemd/user/wezterm-mux-server.service
systemctl --user daemon-reload
```
