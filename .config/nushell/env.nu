# Nushell environment configuration
# Shared across macOS/Linux

# Starship shell detection
$env.STARSHIP_SHELL = "nu"

# XDG Base Directory compatibility
if ("XDG_CONFIG_HOME" not in $env) {
    $env.XDG_CONFIG_HOME = $"($env.HOME)/.config"
}
if ("XDG_DATA_HOME" not in $env) {
    $env.XDG_DATA_HOME = $"($env.HOME)/.local/share"
}
if ("XDG_CACHE_HOME" not in $env) {
    $env.XDG_CACHE_HOME = $"($env.HOME)/.cache"
}

# Enable zoxide if available
if (which zoxide | is-empty | not) {
    # zoxide initialization will be done in config.nu
}

# Common environment variables
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"

# Add $HOME/.local/bin to PATH if it exists
let local_bin = $"($env.HOME)/.local/bin"
if ($local_bin | path exists) {
    $env.PATH = ($env.PATH | split row (if ($nu.os-info.name == "windows") { ";" } else { ":" })
        | append $local_bin
        | uniq
        | str join (if ($nu.os-info.name == "windows") { ";" } else { ":" })
    )
}

# Load private environment overrides if they exist
let private_env = $"($env.HOME)/.config/nushell/env.private.nu"
if ($private_env | path exists) {
    source $private_env
}
