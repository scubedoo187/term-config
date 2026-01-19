{
  description = "Cross-platform terminal setup with WezTerm, Fish, Starship (macOS/Linux)";

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
      in
      {
        # Development environment with all tools
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Core terminal tools
            wezterm
            fish
            starship
            
            # Essential utilities
            git
            zoxide
            fzf
            ripgrep
            fd
            bat
            eza
            fnm
            
            postgresql # psql client
            
            # Optional
            neovim
            tmux
          ];
          
          shellHook = ''
            echo "Terminal dev environment loaded"
            echo "Available: wezterm, fish, starship, zoxide, fzf, rg, fd, bat, eza"
          '';
        };

        # Profile packages (nix profile install ./)
        packages.default = pkgs.symlinkJoin {
          name = "dotfiles-env";
          paths = with pkgs; [
            wezterm
            fish
            starship
            zoxide
            fzf
            ripgrep
            fd
            bat
            eza
            fnm
            
            postgresql # psql client
          ];
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
