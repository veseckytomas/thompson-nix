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
{...}: {
  programs.git = {
    enable = true;
    signing.format = "openpgp";
    settings.user = {
      email = "vesecky@proton.me";
      name = "Tomáš Vesecký";
    };
    signing = {
      signByDefault = true;
      key = "86020E9B84233A43E5249EC4E397E45D1BC4E984";
    };
  };
  catppuccin.delta = {
    enable = true;
    flavor = "mocha";
  };
  home.file."Git/migrate.sh".source = ./migrate.sh;
  imports = [
    ./aliases.nix
    ./settings
  ];
}
