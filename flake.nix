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
      TomasVesa-NTB2-NixOS = lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/TomasVesa-NTB2-NixOS/configuration.nix
          ./modules/common/common.nix
          ./modules/common/locale.nix
          ./modules/common/packages.nix
          ./modules/common/users.nix
          ./modules/desktopManagers/lightdm.nix
          ./modules/windowManagers/gnome.nix
          ./modules/windowManagers/qtile.nix
        ];
      };

      TomasVesa-NTB-NixOS = lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/TomasVesa-NTB-NixOS/configuration.nix
          ./modules/common/common.nix
          ./modules/common/locale.nix
          ./modules/common/packages.nix
          ./modules/common/users.nix
          ./modules/windowManagers/gnome.nix
          ./modules/windowManagers/qtile.nix
        ];
      };
    };
  };
}
