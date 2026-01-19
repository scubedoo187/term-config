# XDG Base Directory
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_CACHE_HOME $HOME/.cache

# Nix (make nix command available in Fish)
if test -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
end

# Editor
set -gx EDITOR nvim
set -gx VISUAL nvim

# Nix PATH
if test -d $HOME/.nix-profile/bin
    fish_add_path $HOME/.nix-profile/bin
end

# Local bin
if test -d $HOME/.local/bin
    fish_add_path $HOME/.local/bin
end

# Cargo bin
if test -d $HOME/.cargo/bin
    fish_add_path $HOME/.cargo/bin
end

# Homebrew (macOS)
if test -d /opt/homebrew/bin
    fish_add_path /opt/homebrew/bin
end
if test -d /opt/homebrew/sbin
    fish_add_path /opt/homebrew/sbin
end

# Intel Mac Homebrew (fallback only - skip on Apple Silicon)
# On Apple Silicon, /usr/local triggers Rosetta. Only add if no ARM brew.
if test -d /usr/local/bin
    and not test -d /opt/homebrew/bin
    fish_add_path /usr/local/bin
end
