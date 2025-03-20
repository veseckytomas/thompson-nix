#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: vesecky@proton.me
# GitHub: veseckytomas
# GitLab: vesecky.tomas
{
  description = "Thompson NixOS config flake";

  inputs = {
    catppuccin.url = "github:catppuccin/nix";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "nixpkgs/nixos-24.11-small";
    home-manager.url = "github:nix-community/home-manager";
    nixvim.url = "github:nix-community/nixvim";
    home-manager-stable.url = "github:nix-community/home-manager/release-24.11";
    nixvim-stable.url = "github:nix-community/nixvim/nixos-24.11";
    zen-browser.url = "github:MarceColl/zen-browser-flake";
    asus-numberpad-driver.url = "github:asus-linux-drivers/asus-numberpad-driver";
    hyprland = {
      type = "git";
      url = "https://github.com/hyprwm/Hyprland";
      submodules = true;
    };
    "2048" = {
      type = "github";
      owner = "mevdschee";
      repo = "2048.c";
      flake = false;
    };
    sddm-theme = {
      type = "github";
      owner = "MarianArlt";
      repo = "sddm-sugar-dark";
      flake = false;
    };
    kulala-nvim = {
      type = "github";
      owner = "mistweaverco";
      repo = "kulala.nvim";
      flake = false;
    };
    render-markdown-nvim = {
      type = "github";
      owner = "MeanderingProgrammer";
      repo = "render-markdown.nvim";
      flake = false;
    };
    zsh-syntax-highlighting = {
      type = "github";
      owner = "zsh-users";
      repo = "zsh-syntax-highlighting";
      flake = false;
    };
    zsh-completions = {
      type = "github";
      owner = "zsh-users";
      repo = "zsh-completions";
      flake = false;
    };
    zsh-autosuggestions = {
      type = "github";
      owner = "zsh-users";
      repo = "zsh-autosuggestions";
      flake = false;
    };
    zsh-autopair = {
      type = "github";
      owner = "hlissner";
      repo = "zsh-autopair";
      flake = false;
    };
    zsh-fzf-tab = {
      type = "github";
      owner = "Aloxaf";
      repo = "fzf-tab";
      flake = false;
    };
    zsh-atuin = {
      type = "github";
      owner = "atuinsh";
      repo = "atuin";
      flake = false;
    };
    tmux-sensible = {
      type = "github";
      owner = "tmux-plugins";
      repo = "tmux-sensible";
      flake = false;
    };
    tmux-navigator = {
      type = "github";
      owner = "christoomey";
      repo = "vim-tmux-navigator";
      flake = false;
    };
    tmux-yank = {
      type = "github";
      owner = "tmux-plugins";
      repo = "tmux-yank";
      flake = false;
    };
  };

  # outputs = {self, ...} @ inputs: let
  outputs = inputs: let
    system = "x86_64-linux";
    username = "vesecto";
    pkgs = import inputs.nixpkgs {
      inherit system;
      config = {allowUnfree = true;};
    };
    pkgs-stable = import inputs.nixpkgs-stable {
      inherit system;
    };
  in {
    nixosConfigurations = {
      TomasVesa-PC-NixOS = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs username system;};
        modules = [
          ./hosts/TomasVesa-PC-NixOS/configuration.nix
          ./modules
        ];
      };

      TomasVesa-NTB-NixOS = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs username system;};
        modules = [
          inputs.asus-numberpad-driver.nixosModules.default
          ./hosts/TomasVesa-NTB-NixOS/configuration.nix
          ./modules/common/notebook.nix
          ./modules/common/gaming.nix
          ./modules
        ];
      };

      TomasVesa-Portable-NixOS = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs username system;};
        modules = [
          ./hosts/TomasVesa-Portable-NixOS/configuration.nix
          ./modules/common/notebook.nix
          ./modules
        ];
      };

      Karthik = inputs.nixpkgs-stable.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {
          inherit inputs username;
          pkgs-stable = import inputs.nixpkgs-stable {
            system = "aarch64-linux";
          };
        };
        modules = [
          ./hosts/Karthik/configuration.nix
          ./modules/server.nix
        ];
      };

      NixOSServerTemplate = inputs.nixpkgs-stable.lib.nixosSystem {
        specialArgs = {inherit inputs username system pkgs-stable;};
        modules = [
          ./hosts/NixOSServerTemplate/configuration.nix
          ./modules/server.nix
        ];
      };

      Reyhan = inputs.nixpkgs-stable.lib.nixosSystem {
        specialArgs = {inherit inputs username system pkgs-stable;};
        modules = [
          ./hosts/Reyhan/configuration.nix
          ./modules/server.nix
        ];
      };

      Merete = inputs.nixpkgs-stable.lib.nixosSystem {
        specialArgs = {inherit inputs username system pkgs-stable;};
        inherit system;
        modules = [
          ./hosts/Merete/configuration.nix
          ./modules/server.nix
        ];
      };

      rescueIso = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs username system pkgs-stable;};
        modules = [
          ./hosts/rescueIso/configuration.nix
        ];
      };

      installIso = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs username system pkgs-stable;};
        modules = [
          ./hosts/installIso/configuration.nix
        ];
      };
    };

    homeConfigurations = {
      vesecto = inputs.home-manager.lib.homeManagerConfiguration {
        extraSpecialArgs = {inherit inputs system username;};
        inherit pkgs;
        modules = [
          ./home-manager/vesecto
          inputs.catppuccin.homeManagerModules.catppuccin
          inputs.nixvim.homeManagerModules.nixvim
        ];
      };

      vesecto-server = inputs.home-manager-stable.lib.homeManagerConfiguration {
        extraSpecialArgs = {inherit username;};
        pkgs = pkgs-stable;
        modules = [
          ./home-manager/vesecto-server
          inputs.catppuccin.homeManagerModules.catppuccin
          inputs.nixvim-stable.homeManagerModules.nixvim
        ];
      };

      vesecto-server-arm = inputs.home-manager-stable.lib.homeManagerConfiguration {
        extraSpecialArgs = {inherit username;};
        pkgs = import inputs.nixpkgs-stable {
          system = "aarch64-linux";
        };
        modules = [
          ./home-manager/vesecto-server
          inputs.catppuccin.homeManagerModules.catppuccin
          inputs.nixvim-stable.homeManagerModules.nixvim
        ];
      };
    };
  };
}
