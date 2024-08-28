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
{pkgs, ...}: {
  # Define a user accounts
  users.users.vesecto = {
    isNormalUser = true;
    description = "Tomas Vesecky";
    extraGroups = ["networkmanager" "wheel" "docker" "user-with-access-to-virtualbox" "video"];
    shell = pkgs.zsh;
  };
}
