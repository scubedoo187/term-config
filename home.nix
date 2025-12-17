{ config, pkgs, lib, osType ? "linux", ... }:

{
  # Home Manager configuration for cross-platform terminal setup
  home = {
    username = lib.mkDefault (builtins.getEnv "USER");
    homeDirectory = if osType == "macos" 
      then "/Users/${builtins.getEnv "USER"}" 
      else "/home/${builtins.getEnv "USER"}";
    stateVersion = "23.11";

    packages = with pkgs; [
      # Core terminal tools
      wezterm
      nushell
      starship
      
      # Essential utilities
      git
      zoxide
      fzf
      ripgrep
      fd
      bat
      eza
      
      # Optional
      neovim
      tmux
      
      # Fonts (works on both platforms via nix)
      (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    ];

    # Symlink dotfiles
    file = {
      ".config/wezterm" = {
        source = ./.config/wezterm;
        recursive = true;
      };
      ".config/nushell" = {
        source = ./.config/nushell;
        recursive = true;
      };
      ".config/starship.toml" = {
        source = ./.config/starship.toml;
      };
    };
  };

  # Program configurations
  programs = {
    # Nushell
    nushell = {
      enable = true;
      package = pkgs.nushell;
      configFile.source = ./.config/nushell/config.nu;
      envFile.source = ./.config/nushell/env.nu;
    };

    # Starship prompt
    starship = {
      enable = true;
      settings = builtins.fromTOML (builtins.readFile ./.config/starship.toml);
    };

    # Zoxide
    zoxide = {
      enable = true;
      enableNushellIntegration = true;
    };

    # FZF
    fzf = {
      enable = true;
      enableNushellIntegration = true;
    };

    # Git configuration (minimal)
    git = {
      enable = true;
      extraConfig = {
        core.editor = "nvim";
        init.defaultBranch = "main";
      };
    };

    # Bash (for compatibility if needed)
    bash = {
      enable = true;
    };

    # Direnv (optional)
    direnv = {
      enable = false;
      nix-direnv.enable = false;
    };
  };

  # Shell aliases via home-manager
  home.shellAliases = {
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
  };

  # Manage session and environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    STARSHIP_SHELL = "nu";
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
    XDG_DATA_HOME = "${config.home.homeDirectory}/.local/share";
    XDG_CACHE_HOME = "${config.home.homeDirectory}/.cache";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}
