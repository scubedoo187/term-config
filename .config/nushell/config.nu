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
# OPTIONAL UTILITIES - FZF
# ============================================================================

let fzf_path = $"($env.HOME)/.nix-profile/bin/fzf"
if ($fzf_path | path exists) {
    $env.FZF_DEFAULT_OPTS = "--height 50% --reverse --border"
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
