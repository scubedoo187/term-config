# eza aliases
if type -q eza
    alias ls 'eza --group-directories-first --icons'
    alias ll 'eza --long --group-directories-first --icons'
    alias la 'eza --all --group-directories-first --icons'
    alias lla 'eza --all --long --group-directories-first --icons'
    alias tree 'eza --tree --icons'
end

# bat alias
if type -q bat
    alias cat 'bat --theme=TwoDark'
end

# Navigation shortcuts
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'
alias ..... 'cd ../../../..'

# mkcd: create directory and cd into it
function mkcd
    mkdir -p $argv[1] && cd $argv[1]
end
