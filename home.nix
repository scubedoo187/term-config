{ config, pkgs, lib, osType ? "linux", ... }:

{
  home = {
    username = lib.mkDefault (builtins.getEnv "USER");
    homeDirectory = if osType == "macos" 
      then "/Users/${builtins.getEnv "USER"}" 
      else "/home/${builtins.getEnv "USER"}";
    stateVersion = "23.11";

    packages = with pkgs; [
      wezterm
      fish
      starship
      
      git
      zoxide
      fzf
      ripgrep
      fd
      bat
      eza
      
      neovim
      tmux
      
      (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    ];

    file = {
      ".config/wezterm" = {
        source = ./.config/wezterm;
        recursive = true;
      };
      ".config/fish" = {
        source = ./.config/fish;
        recursive = true;
      };
      ".config/starship.toml" = {
        source = ./.config/starship.toml;
      };
    };
  };

  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        set -g fish_greeting
        
        if type -q direnv
            direnv hook fish | source
        end
        
        if type -q zoxide
            zoxide init fish | source
        end
        
        if type -q fzf
            fzf --fish | source
        end
        
        if type -q starship
            starship init fish | source
        end
      '';
      functions = {
        nix-shell = "command nix-shell --run fish $argv";
        mkcd = "mkdir -p $argv[1] && cd $argv[1]";
      };
    };

    starship = {
      enable = true;
      enableFishIntegration = false;
      settings = builtins.fromTOML (builtins.readFile ./.config/starship.toml);
    };

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
      extraConfig = {
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
