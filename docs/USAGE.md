# Usage Guide

## Default Setup

The default workflow is tmux-first persistence:

```text
Ghostty  = GUI renderer
Fish     = login shell and shared UX
Starship = prompt
tmux     = sessions, panes, windows, persistence
```

Ghostty owns nothing but rendering, so sessions survive a GUI restart and the
key layer is identical on every OS.

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
```

`term = xterm-256color` intentionally avoids tmux/ncurses warnings such as:

```text
missing or unsuitable terminal: xterm-ghostty
```

Validate:

```bash
ghostty +validate-config --config-file ~/.config/ghostty/config
ghostty +show-config | rg '^(command|term|font-family|theme)'
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
| `CMD+SHIFT+M` | Toggle mouse reporting across every tab |

Mouse reporting starts on, so terminal applications receive mouse input. Toggle
it off for native selection and `copy-on-select`.

### Fish/FZF

| Key | Action |
|-----|--------|
| `CTRL+R` | History search |
| `CTRL+T` | File finder |
| `ALT+C` | Directory jump |

## Retiring an older WezTerm setup

This repo previously ran WezTerm with a persistent `wezterm-mux-server`. tmux
does that job now, and the agent is gone from the configs. A machine that was
set up before the switch still has it registered, where it keeps restarting and
growing `mux-server-error.log`, so clear it once per machine.

### macOS

```bash
launchctl bootout "gui/$(id -u)/com.wezterm.mux-server" 2>/dev/null || true
rm -f ~/Library/LaunchAgents/com.wezterm.mux-server.plist
rm -rf ~/.local/share/wezterm ~/.wezterm.lua ~/.config/wezterm*
```

### Linux

```bash
systemctl --user disable --now wezterm-mux-server 2>/dev/null || true
rm -f ~/.config/systemd/user/wezterm-mux-server.service
systemctl --user daemon-reload
rm -rf ~/.local/share/wezterm ~/.wezterm.lua ~/.config/wezterm*
```
