#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: vesecky@proton.me
# GitHub: veseckytomas
# GitLab: vesecky.tomas
{
  description = "<project description>";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      src = nixpkgs.lib.fileset.toSource {
        root = ./.;
        fileset = nixpkgs.lib.fileset.unions [ ./flake.nix ];
      };
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            # --- STACK: python ---
            # python312 uv
            # --- STACK: rust ---
            # rustc cargo rustfmt clippy
            # --- STACK: node ---
            # nodejs_22
            # --- STACK: go ---
            # go gopls
            # --- STACK: shell ---
            # shellcheck shfmt
          ];
        };
      });

      checks = forAllSystems (pkgs: {
        # `nix flake check` would evaluate everything; build this attr directly in CI to lint alone.
        lint = pkgs.runCommand "lint"
          {
            nativeBuildInputs = [ pkgs.nixfmt-rfc-style ];
          } ''
          cd ${src}
          nixfmt --check flake.nix
          touch $out
        '';
      });
    };
}
