# fnm (Fast Node Manager)
# Enables per-project Node version switching via .nvmrc/.node-version
if type -q fnm
    if not set -q XDG_DATA_HOME
        set -gx XDG_DATA_HOME $HOME/.local/share
    end

    set -gx FNM_DIR "$XDG_DATA_HOME/fnm"
    fnm env --shell fish --use-on-cd | source
end
