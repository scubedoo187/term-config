# Suppress fish greeting
set -g fish_greeting

# FZF options
set -gx FZF_DEFAULT_OPTS "--height 50% --reverse --border --color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796 --color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6 --color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796"
set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always --line-range :500 {} 2>/dev/null || ls -la {}'"
set -gx FZF_ALT_C_OPTS "--preview 'eza --tree --color=always {} | head -200'"

# Direnv (FIRST - before prompt modifications)
if type -q direnv
    direnv hook fish | source
end

# Zoxide
if type -q zoxide
    zoxide init fish | source
end

# FZF keybindings (Ctrl+R, Ctrl+T, Alt+C)
if type -q fzf
    fzf --fish | source
end

# Starship prompt (LAST - overrides prompt)
if type -q starship
    starship init fish | source
end

# nix-shell wrapper to use Fish
function nix-shell
    command nix-shell --run fish $argv
end
