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
  pkgs,
  inputs,
  ...
}: let
  tock = pkgs.callPackage ./package.nix {
    src = inputs.tock;
    # Upstream tags releases but the input tracks master, so flake.lock is the pin.
    version = "2.0.4-unstable-${builtins.substring 0 7 inputs.tock.rev}";
  };
  # The Obsidian vault, where the assistant agent reads the log and git tracks it.
  dataFile = "/home/vesecto/Git/Personal/thompson-obsidian/thompson-obsidian.new/context/tock.txt";
in {
  # tock.yaml, not sessionVariables: an agent's non-login context has no shell env.
  xdg.configFile."tock/tock.yaml".text = ''
    backend: file

    file:
      path: ${dataFile}

    check_updates: false

    time_format: "24"
  '';

  home.packages = [tock];
}
