# Nushell environment configuration
# Shared across macOS/Linux

# XDG Base Directory compatibility
if ("XDG_CONFIG_HOME" not-in $env) {
    $env.XDG_CONFIG_HOME = $"($env.HOME)/.config"
}
if ("XDG_DATA_HOME" not-in $env) {
    $env.XDG_DATA_HOME = $"($env.HOME)/.local/share"
}
if ("XDG_CACHE_HOME" not-in $env) {
    $env.XDG_CACHE_HOME = $"($env.HOME)/.cache"
}

# Common environment variables
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"

# Add ~/.nix-profile/bin to PATH for Nix packages
let nix_bin = $"($env.HOME)/.nix-profile/bin"
if ($nix_bin | path exists) {
    $env.PATH = ($env.PATH | split row (char esep) | prepend $nix_bin | uniq)
}

# Add $HOME/.local/bin to PATH if it exists
let local_bin = $"($env.HOME)/.local/bin"
if ($local_bin | path exists) {
    $env.PATH = ($env.PATH | split row (char esep) | append $local_bin | uniq)
}

# ============================================================================
# STARSHIP PROMPT INITIALIZATION (Official method)
# ============================================================================
# Generate starship init and source it
let starship_path = $"($env.HOME)/.nix-profile/bin/starship"
if ($starship_path | path exists) {
    $env.STARSHIP_SHELL = "nu"
    $env.STARSHIP_SESSION_KEY = (random chars -l 16)
    $env.PROMPT_MULTILINE_INDICATOR = (^$starship_path prompt --continuation)
    $env.PROMPT_INDICATOR = ""
    $env.PROMPT_COMMAND = {||
        let cmd_duration = if $env.CMD_DURATION_MS == "0823" { 0 } else { $env.CMD_DURATION_MS }
        (
            ^$"($env.HOME)/.nix-profile/bin/starship" prompt
                --cmd-duration $cmd_duration
                $"--status=($env.LAST_EXIT_CODE)"
                --terminal-width (term size).columns
        )
    }
    $env.PROMPT_COMMAND_RIGHT = {||
        let cmd_duration = if $env.CMD_DURATION_MS == "0823" { 0 } else { $env.CMD_DURATION_MS }
        (
            ^$"($env.HOME)/.nix-profile/bin/starship" prompt
                --right
                --cmd-duration $cmd_duration
                $"--status=($env.LAST_EXIT_CODE)"
                --terminal-width (term size).columns
        )
    }
}
