{
  description = "Thompson NixOS config flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = { allowUnfree = true; };
    };
    lib = nixpkgs.lib;
  in {
    nixosConfigurations = {
      testbox = lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/TomasVesa-NTB2-NixOS/configuration.nix
        ];
      };
    };
  };
}
