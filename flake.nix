{
  description = "Cross-platform terminal setup with WezTerm, Nushell, Starship (macOS/Linux)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, home-manager }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        isDarwin = pkgs.stdenv.isDarwin;
        isLinux = pkgs.stdenv.isLinux;
      in
      {
        # Development environment with all tools
        devShells.default = pkgs.mkShell {
          buildInputs = [
            # Core terminal tools
            pkgs.wezterm
            pkgs.nushell
            pkgs.starship
            
            # Essential utilities
            pkgs.git
            pkgs.zoxide
            pkgs.fzf
            pkgs.ripgrep
            pkgs.fd
            pkgs.bat
            pkgs.eza
            
            # Optional
            pkgs.neovim
            pkgs.tmux
          ];
          
          shellHook = ''
            echo "Terminal dev environment loaded"
            echo "Available: wezterm, nu, starship, zoxide, fzf, rg, fd, bat, eza"
          '';
        };

        # Profile packages (nix profile install ./)
        packages.default = pkgs.symlinkJoin {
          name = "dotfiles-env";
          paths = with pkgs; [
            wezterm
            nushell
            starship
            zoxide
            fzf
            ripgrep
            fd
            bat
            eza
          ];
          postBuild = ''
            mkdir -p $out/etc/profile.d
          '';
        };
      }
    ) // {
      # Home Manager support for macOS/Linux
      homeConfigurations = {
        "user@macos" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages."aarch64-darwin";
          modules = [ ./home.nix ];
          extraSpecialArgs = { 
            osType = "macos";
          };
        };
        
        "user@linux" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages."x86_64-linux";
          modules = [ ./home.nix ];
          extraSpecialArgs = { 
            osType = "linux";
          };
        };
      };
    };
}
