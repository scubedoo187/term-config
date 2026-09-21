# Suppress fish greeting
set -g fish_greeting

set -g __term_config_cache_dir "$XDG_CACHE_HOME/term-config/fish"

function __term_config_source_cached_init --description "Source cached shell init output"
    set -l cache_name $argv[1]
    set -l generator $argv[2..]
    set -l cache_file "$__term_config_cache_dir/$cache_name"

    # -s (not -r): an empty cache file means a previous generation failed,
    # so regenerate instead of sourcing nothing forever.
    if test -s "$cache_file"
        source "$cache_file"
        return 0
    end

    if not type -q $generator[1]
        return 1
    end

    mkdir -p "$__term_config_cache_dir"
    set -l tmp_file "$cache_file.tmp.$fish_pid"
    if $generator >"$tmp_file" 2>/dev/null; and test -s "$tmp_file"
        mv -f "$tmp_file" "$cache_file"
        source "$cache_file"
    else
        # Never leave a broken cache behind; fall back to direct init.
        rm -f "$tmp_file"
        $generator | source
    end
end

# FZF options
set -gx FZF_DEFAULT_OPTS "--height 50% --reverse --border --color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796 --color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6 --color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796"
set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always --line-range :500 {} 2>/dev/null || ls -la {}'"
set -gx FZF_ALT_C_OPTS "--preview 'eza --tree --color=always {} | head -200'"

# Direnv (FIRST - before prompt modifications)
if type -q direnv
    __term_config_source_cached_init direnv-init.fish direnv hook fish
end

# Zoxide
if type -q zoxide
    zoxide init fish | source
end

# FZF keybindings (Ctrl+R, Ctrl+T, Alt+C)
if type -q fzf
    __term_config_source_cached_init fzf-init.fish fzf --fish
end

# Starship prompt (LAST - overrides prompt)
if type -q starship
    __term_config_source_cached_init starship-init.fish starship init fish --print-full-init
end

# nix-shell wrapper to use Fish
function nix-shell
    command nix-shell --run fish $argv
end

