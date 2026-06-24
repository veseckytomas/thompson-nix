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
#
# nixos-run: TUI to control NixOS rebuilding.
#
# `flakePath` is baked into the script as the default repo location; it can be
# overridden at runtime via the NIXOS_RUN_FLAKE environment variable.
{
  writeShellApplication,
  gum,
  git,
  jq,
  fd,
  trash-cli,
  gawk,
  curl,
  gnugrep,
  coreutils,
  flakePath ? "/home/vesecto/Git/Personal/thompson-nix",
}: let
  gum' = gum.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./gum-choose-keymap.patch];
  });
in
  writeShellApplication {
    name = "nixos-run";
    runtimeInputs = [
      gum'
      git
      jq
      fd
      trash-cli
      gawk
      curl
      gnugrep
      coreutils
    ];
    text = builtins.replaceStrings ["@flakePath@"] [flakePath] (builtins.readFile ./nixos-run.sh);
  }
