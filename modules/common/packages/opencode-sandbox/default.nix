#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
{
  pkgs,
  image,
}: let
  gnupgTools = pkgs.callPackage ../../../../home-manager/vesecto/modules/gnupg/tools.nix {};
in
  pkgs.writeShellApplication {
    name = "opencode-sandbox";
    runtimeInputs = [pkgs.bash pkgs.docker pkgs.curl pkgs.coreutils pkgs.util-linux];
    text = ''
      # Baked at build time: stream script for the matching image and its tag.
      export OPENCODE_SANDBOX_IMAGE_STREAM="${image}"
      export OPENCODE_SANDBOX_IMAGE="${image.imageName}:${image.imageTag}"
      export OPENCODE_SANDBOX_GPG_DECRYPT="${gnupgTools.gpg-decrypt-hardened}/bin/gpg-decrypt-hardened"
      exec bash ${./launcher.sh} "$@"
    '';
  }
