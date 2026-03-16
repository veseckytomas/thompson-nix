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
  username,
  ...
}: {
  # Define a user accounts
  users.users.${username} = {
    isNormalUser = true;
    description = "Tomas Vesecky";
    extraGroups = ["networkmanager" "wheel" "docker" "video" "input" "libvirtd"];
    shell = pkgs.zsh;
  };
}
