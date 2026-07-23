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
# ykman-run: TUI to manage YubiKey OpenPGP touch policies (auth / sign / decrypt).
{
  writeShellApplication,
  yubikey-manager,
  gum,
  gawk,
  coreutils,
}: let
  # Reuse nixos-run's gum patch (hjkl nav, space toggle, `a` select-all).
  gum' = gum.overrideAttrs (old: {
    patches = (old.patches or []) ++ [../nixos-run/gum-choose-keymap.patch];
  });
in
  writeShellApplication {
    name = "ykman-run";
    runtimeInputs = [
      gum'
      yubikey-manager
      gawk
      coreutils
    ];
    text = builtins.readFile ./ykman-run.sh;
  }
