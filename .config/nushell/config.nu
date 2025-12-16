# Nushell main configuration
# Wires Starship prompt, configures core UX, loads optional utilities

# ============================================================================
# STARSHIP PROMPT INTEGRATION
# ============================================================================

# Initialize Starship as prompt if available
if (which starship | is-empty | not) {
    use std "assert"
    
    # Define Starship initialization
    def --wrapped starship_prompt [] {
        starship prompt --terminal-width (term size).columns --status $env.LAST_EXIT_CODE
    }
    
    # Set as main prompt
    $env.PROMPT_COMMAND = {|| starship_prompt }
    
    # Disable right prompt and default indicators to avoid duplication
    $env.PROMPT_COMMAND_RIGHT = ""
    $env.TRANSIENT_PROMPT_COMMAND = ""
} else {
    # Fallback if starship not available
    $env.PROMPT_COMMAND = {|| 
        let level = ($env.NESTING_LEVEL? // 0)
        (">" * ($level + 1) + " ")
    }
}

# ============================================================================
# CORE NUSHELL SETTINGS
# ============================================================================

# Text editing
$env.config.edit_mode = "vi"
$env.config.buffer_editor = "nvim"

# History settings
$env.config.history = {
    max_size: 100_000
    sync_on_enter: true
    file_format: "sqlite"
    isolation: false
}

# Completions
$env.config.completions = {
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

# Error style
$env.config.error_style = "fancy"

# Display settings
$env.config.table = {
    mode: "basic"
    index_mode: "always"
    show_empty: false
    padding: { left: 1, right: 1 }
    header_on_separator: false
    abbreviation_threshold: 60
}

# ============================================================================
# OPTIONAL UTILITIES - ZOXIDE
# ============================================================================

def load_zoxide [] {
    if (which zoxide | is-empty | not) {
        # Initialize zoxide for Nushell
        zoxide init nushell | save --raw $"($env.XDG_CONFIG_HOME)/nushell/zoxide.nu"
        source $"($env.XDG_CONFIG_HOME)/nushell/zoxide.nu"
    }
}

# Try to load zoxide
try {
    load_zoxide
} catch {
    # zoxide not available, continue without it
}

# ============================================================================
# OPTIONAL UTILITIES - FZF
# ============================================================================

def load_fzf [] {
    if (which fzf | is-empty | not) {
        # Configure FZF for Nushell
        $env.FZF_DEFAULT_OPTS = "--height 50% --reverse --border"
        
        # Optional: fzf history search
        # Can be wired to a keybinding if needed
    }
}

# Try to load fzf configuration
try {
    load_fzf
} catch {
    # fzf not available, continue without it
}

# ============================================================================
# OPTIONAL UTILITIES - MODERN REPLACEMENTS (gated)
# ============================================================================

# Use modern replacements if available, fallback to standard commands
def _get_command [cmd standard_cmd] {
    if (which $cmd | is-empty | not) {
        $cmd
    } else {
        $standard_cmd
    }
}

# Setup command aliases for modern alternatives if available
# These are optional and don't break if missing

if (which bat | is-empty | not) {
    alias cat = bat --theme Monokai
}

if (which eza | is-empty | not) {
    alias ls = eza --group-directories-first
    alias ll = eza --long --group-directories-first
    alias la = eza --all --group-directories-first
    alias lla = eza --all --long --group-directories-first
} else {
    alias ll = ls -la
    alias la = ls -a
    alias lla = ls -la
}

if (which rg | is-empty | not) {
    # ripgrep available as enhanced grep
}

if (which fd | is-empty | not) {
    # fd available as enhanced find
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Cross-platform mkcd (mkdir + cd)
def mkcd [path: string] {
    mkdir $path
    cd $path
}

# Directory navigation helper
def .. [] {
    cd ..
}

def ... [] {
    cd ../..
}

def .... [] {
    cd ../../..
}

# ============================================================================
# KEYBINDINGS
# ============================================================================

$env.config.keybindings = [
    # Vi-like behavior (already set by edit_mode = "vi")
    # Add custom keybindings here if needed
]

# ============================================================================
# LOAD PRIVATE CONFIG (if exists)
# ============================================================================

let private_config = $"($env.XDG_CONFIG_HOME)/nushell/config.private.nu"
if ($private_config | path exists) {
    source $private_config
}
