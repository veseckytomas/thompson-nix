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
  environment.systemPackages = [
    # pkgs.varia
    # pkgs.python312
    # (pkgs.python312.withPackages (python-pkgs: [
    #   python-pkgs.platformdirs
    #   python-pkgs.numpy
    # ]))
    # (pkgs.python312.withPackages (python-pkgs: [
    #   python-pkgs.pandas
    # ]))
  ];
}
