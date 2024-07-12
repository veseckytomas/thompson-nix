{
  description = "Thompson NixOS config flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.05";
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
      testbox = lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/TomasVesa-NTB2-NixOS/configuration.nix
          # ./configuration.nix
        ];
      };
    };
  };
}
