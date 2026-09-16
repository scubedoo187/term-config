# term-config

Cross-platform terminal configuration for **Ghostty/WezTerm + Fish + Starship + tmux**.

The current default workflow is **terminal GUI as renderer, tmux as persistence**. Ghostty is preferred on macOS; WezTerm remains available as a lightweight GUI without native mux/workspace persistence.

## Features

- **Fish** as default shell with **Starship** prompt
- **tmux** for sessions, windows, panes, and persistence
- **Ghostty** config managed under `~/.config/ghostty/config`
- **WezTerm** kept minimal; no `Ctrl+A` leader or native mux-server dependency
- **Nix-first** installation, with Homebrew-friendly paths
- Unified JetBrainsMono Nerd Font based UI

## Quick Start

```bash
# Clone
git clone https://github.com/scubedoo187/term-config.git ~/term-config

# Symlink configs
ln -sfn ~/term-config/.config/ghostty ~/.config/ghostty
ln -sfn ~/term-config/.config/wezterm ~/.config/wezterm
ln -sfn ~/term-config/.config/fish ~/.config/fish
ln -sfn ~/term-config/.config/tmux ~/.config/tmux
ln -sf ~/term-config/.config/starship.toml ~/.config/starship.toml
ln -sf ~/term-config/.config/wezterm/wezterm.lua ~/.wezterm.lua

# Install (Nix)
nix profile install .

# Or install (Homebrew)
brew install --cask ghostty wezterm
brew install fish starship tmux zoxide fzf ripgrep fd bat eza git
```

If Ghostty previously generated `~/Library/Application Support/com.mitchellh.ghostty/config`, remove it so the XDG dotfile remains the single source of truth.

## Session Model

```text
Ghostty or WezTerm GUI
  -> Fish login shell
  -> auto-attach tmux session named "main"
  -> Starship/FZF/zoxide UX inside tmux
```

Ghostty sets `term = xterm-256color` to avoid `missing or unsuitable terminal: xterm-ghostty` in tmux/ncurses environments.

## Keybindings

**tmux Prefix: `Ctrl+A`**

Use tmux for windows, panes, session persistence, and detach/attach behavior.

**GUI terminal**

| Key | Action |
|-----|--------|
| `Cmd+Shift+C` | Copy |
| `Cmd+Shift+V` | Paste |
| `Alt+L` | WezTerm launcher |

**Fish/FZF**

| Key | Action |
|-----|--------|
| `Ctrl+R` | History search |
| `Ctrl+T` | File finder |
| `Alt+C` | Directory jump |

## Onprem DuckDB / dlk Pi Integration

Optional private Pi integration for read-only onprem DuckDB/dlk EDA is documented in:

```text
docs/ONPREM-DUCKDB.md
```

## Maintenance

```bash
./scripts/verify-config.sh
```

Legacy WezTerm mux cleanup tools remain for migration/recovery only:

```bash
./scripts/check-wezterm-mux-health.sh
./scripts/cleanup-wezterm-state.sh
```

## Structure

```text
.config/
  ghostty/
    config              # Ghostty GUI/theme/TERM config
  wezterm/
    wezterm.lua          # Minimal WezTerm renderer config
    modules/
      appearance.lua
      keybindings.lua
  fish/
    config.fish          # Shell config + GUI auto tmux attach
    conf.d/
      env.fish
      aliases.fish
  tmux/
    tmux.conf            # Persistence/key layer
  starship.toml          # Prompt config
home/                    # Configs that land directly in $HOME, not XDG
  claude/
    settings.json        # Claude Code global settings
    statusline-command.sh # Status line mirroring the Starship prompt
  codex/
    config.toml          # Codex CLI config
    AGENTS.md            # Global Codex instructions
    agents/              # Codex subagent definitions
  pi/
    agent/
      settings.json      # pi agent settings, models, MCP
      extensions/        # Local pi extensions (*.ts)
      prompts/  skills/  # Reusable prompts and skills
      *.example.json     # DB connection templates; real ones are gitignored
```

Credentials are never tracked: `auth.json` and the populated `*-psql.json` /
`onprem-duckdb.json` files stay machine-local. On a new machine, copy the
matching `.example.json` and fill it in.

Everything under `home/` is linked per file, never per directory, because
`~/.pi/agent` and `~/.codex` keep credentials, `node_modules` and session state
alongside the tracked configs. The links point at this working copy rather than
`/nix/store`, so Claude Code, Codex and pi can keep rewriting their own settings
and the changes land directly in `git diff`.

## Moving these configs onto a checkout

```sh
scripts/setup-git-filters.sh                 # once per clone; see below
scripts/migrate-home-configs.sh              # dry run: what would move
scripts/migrate-home-configs.sh --apply      # back up, adopt drift, unlink
scripts/normalize-home-paths.sh --apply      # retarget absolute paths at $HOME
nix run home-manager/master -- switch --flake .#user@macos   # or user@linux
scripts/verify-home-links.sh
```

The migration treats the *live* file as authoritative: if it has drifted from
the repo copy, the live version is pulled into the checkout first, so switching
can never replace a working config with a stale one. Originals are copied to
`~/.term-config-backups/<stamp>/`, and
`scripts/migrate-home-configs.sh --rollback <stamp>` puts them back.

No username is hardcoded. `home.nix` derives paths from
`config.home.homeDirectory`, and `normalize-home-paths.sh` rewrites the paths Codex
bakes into its own config to the current `$HOME`. It is scoped to the Codex
files on purpose: `home/pi/agent/onprem-duckdb.example.json` holds `/home/...`
paths that belong to a *remote* host and must not be touched.

### Codex trust blocks are kept out of git

Codex appends a `[projects."<abs path>"]` block with `trust_level = "trusted"`
for every directory it runs in. Those paths exist only on the machine that
created them, so a clean filter strips them from the blob git stores while the
working copy — which `~/.codex/config.toml` links to — keeps them and stays
functional. Nothing is lost: a fresh checkout is simply asked to trust its own
paths again.

The filter command lives in local git config and is not carried by a clone, so
run `scripts/setup-git-filters.sh` once per checkout; `verify-config.sh` fails
if it is missing.

One cosmetic side effect: after Codex edits the file, `git status` keeps listing
`home/codex/config.toml` as modified even though `git diff` is empty, because
git will not trust its stat cache for a filtered path. The staged content is
unaffected — the trust blocks never reach a commit.

## Requirements

- Ghostty or WezTerm
- Fish
- Starship
- tmux
- JetBrainsMono Nerd Font

## License

MIT
