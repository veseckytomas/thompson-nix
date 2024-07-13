{ config, pkgs, ...}:

{
  # Define a user accounts
  users.users.vesecto = {
    isNormalUser = true;
    initialPassword = "P@ssw0rd";
    description = "Tomas Vesecky";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.zsh;
  };
}
