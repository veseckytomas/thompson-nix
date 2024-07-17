{ config, pkgs, ...}:

{
  # Define a user accounts
  users.users.vesecto = {
    isNormalUser = true;
    description = "Tomas Vesecky";
    extraGroups = [ "networkmanager" "wheel" "docker" "user-with-access-to-virtualbox" ];
    shell = pkgs.zsh;
  };
}
