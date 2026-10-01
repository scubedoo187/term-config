{ config, pkgs, lib, osType ? "linux", ... }:

let
  # Where this checkout lives. Derived from homeDirectory so nothing in this
  # file hardcodes a username.
  repoRoot = "${config.home.homeDirectory}/term-config";

  # Every regular file under `dir`, as paths relative to it. Directories are
  # walked; only files come back.
  collectFiles = dir:
    lib.flatten (lib.mapAttrsToList (name: type:
      if type == "directory"
      then map (p: "${name}/${p}") (collectFiles (dir + "/${name}"))
      else [ name ]
    ) (builtins.readDir dir));

  # Link each file individually, never the directory itself: ~/.pi/agent and
  # ~/.codex hold credentials, node_modules and session state next to the
  # tracked configs, and a directory symlink would hide all of it.
  #
  # mkOutOfStoreSymlink points at the working copy rather than /nix/store, so
  # Claude Code, Codex and pi can keep rewriting their own settings files and
  # the edits land straight in `git diff`.
  linkTree = srcPath: srcRel: targetPrefix:
    lib.listToAttrs (map (rel:
      lib.nameValuePair "${targetPrefix}/${rel}" {
        source = config.lib.file.mkOutOfStoreSymlink "${repoRoot}/${srcRel}/${rel}";
      }
    ) (collectFiles srcPath));
in
{
  home = {
    username = lib.mkDefault (builtins.getEnv "USER");
    homeDirectory = if osType == "macos" 
      then "/Users/${builtins.getEnv "USER"}" 
      else "/home/${builtins.getEnv "USER"}";
    stateVersion = "23.11";

    packages = with pkgs; [
      fish
      starship
      
      git
      zoxide
      fzf
      ripgrep
      fd
      bat
      eza
      fnm
      
      postgresql # psql client
      
      neovim
      tmux
      
      nerd-fonts.jetbrains-mono
    ];

    file = {
      ".config/ghostty" = {
        source = ./.config/ghostty;
        recursive = true;
      };
      ".config/fish" = {
        source = ./.config/fish;
        recursive = true;
      };
      ".config/tmux" = {
        source = ./.config/tmux;
        recursive = true;
      };
      ".config/starship.toml" = {
        source = ./.config/starship.toml;
      };

    }
    # Coding-agent configs. These live directly under $HOME rather than
    # $XDG_CONFIG_HOME, so they are sourced from ./home/<app> instead of
    # ./.config. Credentials (auth.json, the populated *-psql.json) are
    # gitignored and stay machine-local; only the .example.json templates
    # are tracked.
    // (linkTree ./home/claude "home/claude" ".claude")
    // (linkTree ./home/codex  "home/codex"  ".codex")
    // (linkTree ./home/pi     "home/pi"     ".pi");
  };

  # Deliberately no programs.fish or programs.starship here. Both generate their
  # own config into the very paths home.file already links to this checkout, so
  # enabling them either collides outright (.config/starship.toml) or shadows the
  # tracked config.fish with a /nix/store copy that cannot be edited in place --
  # and its init would then run every hook a second time. The packages come from
  # home.packages above; the configuration comes from .config/.
  programs = {
    zoxide = {
      enable = true;
      enableFishIntegration = false;
    };

    fzf = {
      enable = true;
      enableFishIntegration = false;
    };

    git = {
      enable = true;
      settings = {
        core.editor = "nvim";
        init.defaultBranch = "main";
      };
    };

    bash = {
      enable = true;
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  home.shellAliases = {
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    STARSHIP_SHELL = "fish";
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
    XDG_DATA_HOME = "${config.home.homeDirectory}/.local/share";
    XDG_CACHE_HOME = "${config.home.homeDirectory}/.cache";
  };

  nixpkgs.config.allowUnfree = true;
}
