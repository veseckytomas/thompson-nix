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
    nixpkgs-stable.url = "nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager";
    nixvim.url = "github:nix-community/nixvim";
    home-manager-stable.url = "github:nix-community/home-manager/release-25.11";
    nixvim-stable.url = "github:nix-community/nixvim/nixos-25.11";
    nix-flatpak.url = "github:gmodena/nix-flatpak/";
    polymc.url = "github:PolyMC/PolyMC";
    yazi.url = "github:sxyazi/yazi";
    asus-numberpad-driver = {
      url = "github:asus-linux-drivers/asus-numberpad-driver";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
      # owner = "MarianArlt";
      # repo = "sddm-sugar-dark";
      owner = "TiagoDamascena";
      repo = "sddm-sugar-catppuccin";
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
    # avante-nvim = {
    #   type = "github";
    #   owner = "yetone";
    #   repo = "avante.nvim";
    #   flake = false;
    # };
    dracula-qt5 = {
      type = "github";
      owner = "dracula";
      repo = "qt5";
      flake = false;
    };
    ratbagd = {
      type = "github";
      owner = "libratbag";
      repo = "libratbag";
      flake = false;
    };
    piper = {
      type = "github";
      owner = "libratbag";
      repo = "piper";
      flake = false;
    };
    get-shit-done-redux = {
      url = "github:open-gsd/get-shit-done-redux/next";
      flake = false;
    };
    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };
    oh-my-openagent = {
      type = "git";
      url = "https://github.com/code-yeongyu/oh-my-openagent";
      ref = "dev";
      submodules = true;
      flake = false;
    };
    caveman = {
      url = "github:JuliusBrussee/caveman";
      flake = false;
    };
    opencode-wakatime = {
      url = "github:angristan/opencode-wakatime";
      flake = false;
    };
    opencode-claude-bridge = {
      url = "github:a-ledu/opencode-claude-bridge";
      flake = false;
    };
    opencode-codex-quota = {
      url = "github:guyinwonder168/opencode-codex-quota";
      flake = false;
    };
    taskwarrior-tui = {
      url = "github:kdheepak/taskwarrior-tui";
      flake = false;
    };
    bun2nix = {
      url = "github:nix-community/bun2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: let
    system = "x86_64-linux";
    username = "vesecto";
    pkgs = import inputs.nixpkgs {
      inherit system;
      config = {allowUnfree = true;};
    };
    pkgs-stable = import inputs.nixpkgs-stable {
      inherit system;
      config = {allowUnfree = true;};
    };
  in {
    nixosConfigurations = {
      TomasVesa-PC-NixOS = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {
          hostname = "TomasVesa-PC-NixOS";
          inherit inputs username system pkgs-stable;
        };
        modules = [
          ./hosts/desktop/TomasVesa-PC-NixOS
          ./modules
        ];
      };

      TomasVesa-NTB-NixOS = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {
          hostname = "TomasVesa-NTB-NixOS";
          inherit inputs username system pkgs-stable;
        };
        modules = [
          inputs.asus-numberpad-driver.nixosModules.default
          ./hosts/desktop/TomasVesa-NTB-NixOS
          ./modules/common/notebook.nix
          ./modules/common/gaming.nix
          ./modules
        ];
      };

      TomasVesa-Portable-NixOS = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs username system pkgs-stable;
          hostname = "TomasVesa-Portable-NixOS";
        };
        modules = [
          ./hosts/desktop/TomasVesa-Portable-NixOS
          ./modules/common/notebook.nix
          ./modules
        ];
      };

      Karthik = inputs.nixpkgs-stable.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {
          inherit inputs username;
        };
        pkgs = import inputs.nixpkgs-stable {
          inherit system;
        };
        modules = [
          ./hosts/server/Karthik
          ./modules/server.nix
        ];
      };

      NixOSServerTemplate = inputs.nixpkgs-stable.lib.nixosSystem {
        specialArgs = {
          inherit inputs username system;
        };
        pkgs = import inputs.nixpkgs-stable {
          inherit system;
        };
        modules = [
          ./hosts/server/NixOSServerTemplate
          ./modules/server.nix
        ];
      };

      Reyhan = inputs.nixpkgs-stable.lib.nixosSystem {
        specialArgs = {
          inherit inputs username system;
        };
        pkgs = import inputs.nixpkgs-stable {
          inherit system;
        };
        modules = [
          ./hosts/server/Reyhan
          ./modules/server.nix
        ];
      };

      Merete = inputs.nixpkgs-stable.lib.nixosSystem {
        specialArgs = {
          inherit inputs username system;
        };
        pkgs = import inputs.nixpkgs-stable {
          inherit system;
        };
        inherit system;
        modules = [
          ./hosts/server/Merete
          ./modules/server.nix
        ];
      };

      rescueIso = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs username system;};
        modules = [
          ./hosts/iso/rescueIso
        ];
      };

      installIso = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs username system;};
        modules = [
          ./hosts/iso/installIso
        ];
      };
    };

    homeConfigurations = {
      vesecto = inputs.home-manager.lib.homeManagerConfiguration {
        extraSpecialArgs = {inherit inputs system username pkgs-stable;};
        inherit pkgs;
        modules = [
          ./home-manager/vesecto
        ];
      };
    };
  };
}
