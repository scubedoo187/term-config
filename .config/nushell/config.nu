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
# OPTIONAL UTILITIES - ZOXIDE
# ============================================================================

# Initialize zoxide if available
let zoxide_path = $"($env.HOME)/.nix-profile/bin/zoxide"
if ($zoxide_path | path exists) {
    # zoxide init generates these aliases
    def-env __zoxide_z [...rest: string] {
        let path = if ($rest | is-empty) {
            $env.HOME
        } else if ($rest | length) == 1 and ($rest.0 == '-') {
            $env.OLDPWD? | default $env.HOME
        } else {
            (^$zoxide_path query --exclude (pwd) -- ...$rest)
        }
        cd $path
    }
    
    def-env __zoxide_zi [...rest: string] {
        let path = (^$zoxide_path query -i -- ...$rest)
        cd $path
    }
    
    alias z = __zoxide_z
    alias zi = __zoxide_zi
    
    # Hook to add directories to zoxide database
    $env.config = ($env.config | merge {
        hooks: {
            pre_prompt: [{||
                ^$"($env.HOME)/.nix-profile/bin/zoxide" add -- (pwd)
            }]
        }
    })
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

# FZF-powered directory navigation
def fzf-cd [] {
    let selected = (fd --type d --hidden --exclude .git | fzf --height 40% --reverse --border --prompt "Dirs > ")
    if ($selected | is-not-empty) {
        cd $selected
    }
}

# ============================================================================
# MODERN CLI ALIASES (only if tools exist)
# ============================================================================

let bat_path = $"($env.HOME)/.nix-profile/bin/bat"
if ($bat_path | path exists) {
    alias cat = bat --theme=TwoDark
}

let eza_path = $"($env.HOME)/.nix-profile/bin/eza"
if ($eza_path | path exists) {
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
def mkcd [path: string] {
    mkdir $path
    cd $path
}

# Navigation shortcuts
alias ... = cd ../..
alias .... = cd ../../..
alias ..... = cd ../../../..

# ============================================================================
# LOAD PRIVATE CONFIG (if exists)
# ============================================================================

let private_config = $"($env.HOME)/.config/nushell/config.private.nu"
if ($private_config | path exists) {
    source $private_config
}
