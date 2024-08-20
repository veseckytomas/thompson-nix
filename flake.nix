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
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    catppuccin,
    nixvim,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = {allowUnfree = true;};
    };
    lib = nixpkgs.lib;
  in {
    nixosConfigurations = {
      TomasVesa-PC-NixOS = lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/TomasVesa-PC-NixOS/configuration.nix
          ./main.nix
          {inherit lib;}
        ];
      };

      TomasVesa-NTB2-NixOS = lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/TomasVesa-NTB2-NixOS/configuration.nix
          ./main.nix
          {inherit lib;}
          ./modules/common/notebook.nix
        ];
      };

      TomasVesa-NTB-NixOS = lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/TomasVesa-NTB-NixOS/configuration.nix
          ./main.nix
          {inherit lib;}
          ./modules/common/notebook.nix
        ];
      };

      TomasVesa-Portable-NixOS = lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/TomasVesa-Portable-NixOS/configuration.nix
          ./main.nix
          {inherit lib;}
          ./modules/common/notebook.nix
        ];
      };

      rescueIso = lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/rescueIso/configuration.nix
        ];
      };

      installIso = lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/installIso/configuration.nix
        ];
      };
    };

    homeConfigurations = {
      vesecto = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home-manager/vesecto/home.nix
          catppuccin.homeManagerModules.catppuccin
          nixvim.homeManagerModules.nixvim
        ];
      };
    };
  };
}
