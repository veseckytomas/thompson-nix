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
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = { allowUnfree = true; };
    };
    lib = nixpkgs.lib;
  in {
    nixosConfigurations = {
      TomasVesa-PC-NixOS = lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/TomasVesa-PC-NixOS/configuration.nix
          ./main.nix
        ];
      };

      TomasVesa-NTB2-NixOS = lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/TomasVesa-NTB2-NixOS/configuration.nix
          ./main.nix
          ./modules/common/notebook.nix
        ];
      };

      TomasVesa-NTB-NixOS = lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/TomasVesa-NTB-NixOS/configuration.nix
          ./main.nix
          ./modules/common/notebook.nix
        ];
      };
    };
  };
}
