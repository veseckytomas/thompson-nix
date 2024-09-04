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
  lib,
  config,
  ...
}: {
  options.notebook.enable = lib.mkEnableOption "Enables notebook module";

  config = lib.mkIf config.notebook.enable {
    services.libinput.enable = true;
    hardware = {
      acpilight.enable = true;
      bluetooth.enable = true;
      bluetooth.powerOnBoot = true;
    };
    environment.systemPackages = with pkgs; [
      blueman
    ];
  };
}
