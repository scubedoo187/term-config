# Nushell main configuration
# Core UX settings and optional utilities

# ============================================================================
# CORE NUSHELL SETTINGS
# ============================================================================

$env.config = {
    show_banner: false
    edit_mode: vi
    buffer_editor: nvim
    
    history: {
        max_size: 100_000
        sync_on_enter: true
        file_format: "sqlite"
        isolation: false
    }
    
    completions: {
        case_sensitive: false
        quick: true
        partial: true
        algorithm: "fuzzy"
        sort: "smart"
        external: {
            enable: true
            max_results: 100
            completer: null
        }
    }
    
    error_style: "fancy"
    
    table: {
        mode: rounded
        index_mode: always
        show_empty: false
        padding: { left: 1, right: 1 }
        header_on_separator: false
    }
    
    render_right_prompt_on_last_line: true
    
    keybindings: [
        {
            name: fzf_history
            modifier: control
            keycode: char_r
            mode: [emacs, vi_normal, vi_insert]
            event: {
                send: executehostcommand
                cmd: "fzf-history"
            }
        }
        {
            name: fzf_files
            modifier: control
            keycode: char_t
            mode: [emacs, vi_normal, vi_insert]
            event: {
                send: executehostcommand
                cmd: "fzf-files"
            }
        }
    ]
}

# ============================================================================
# OPTIONAL UTILITIES - FZF (History search with Ctrl+R)
# ============================================================================

$env.FZF_DEFAULT_OPTS = "--height 50% --reverse --border --color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796 --color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6 --color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796"

# FZF-powered history search
def fzf-history [] {
    let selected = (
        history 
        | get command 
        | reverse 
        | uniq 
        | str join (char newline) 
        | fzf --height 40% --reverse --border --prompt "History > "
    )
    if ($selected | is-not-empty) {
        commandline edit --replace $selected
    }
}

# FZF-powered file finder
def fzf-files [] {
    let selected = (fd --type f --hidden --exclude .git | fzf --height 40% --reverse --border --prompt "Files > ")
    if ($selected | is-not-empty) {
        commandline edit --insert $selected
    }
}

# FZF-powered directory navigation (def --env to persist cd)
def --env fzf-cd [] {
    let selected = (fd --type d --hidden --exclude .git | fzf --height 40% --reverse --border --prompt "Dirs > ")
    if ($selected | is-not-empty) {
        cd $selected
    }
}

# ============================================================================
# OPTIONAL UTILITIES - ZOXIDE
# ============================================================================

# Simple z command using zoxide (use $env.HOME instead of ~)
def --env z [...rest: string] {
    let zoxide_bin = $"($env.HOME)/.nix-profile/bin/zoxide"
    if ($rest | is-empty) {
        cd $env.HOME
    } else {
        let path = (do { ^$zoxide_bin query -- ...$rest } | str trim)
        if ($path | is-not-empty) {
            cd $path
        }
    }
}

# Interactive zoxide with fzf
def --env zi [...rest: string] {
    let zoxide_bin = $"($env.HOME)/.nix-profile/bin/zoxide"
    let path = (do { ^$zoxide_bin query -i -- ...$rest } | str trim)
    if ($path | is-not-empty) {
        cd $path
    }
}

# ============================================================================
# MODERN CLI ALIASES (with existence checks)
# ============================================================================

# Only define aliases if tools exist in PATH
def --env setup-aliases [] {
    # These will be set up at shell start
}

# bat alias (check if exists)
if (which bat | is-not-empty) {
    alias cat = bat --theme=TwoDark
}

# eza aliases (check if exists)  
if (which eza | is-not-empty) {
    alias ls = eza --group-directories-first --icons
    alias ll = eza --long --group-directories-first --icons
    alias la = eza --all --group-directories-first --icons
    alias lla = eza --all --long --group-directories-first --icons
    alias tree = eza --tree --icons
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# mkcd: create directory and cd into it
def --env mkcd [path: string] {
    mkdir $path
    cd $path
}

# Navigation shortcuts
alias ... = cd ../..
alias .... = cd ../../..
alias ..... = cd ../../../..
