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
{pkgs-stable, ...}: {
  programs.bash.enable = true;
  home = {
    file = {
      ".zshrc".source = ./zshrc;
      ".config/zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh".source = ./catppuccin_mocha-zsh-syntax-highlighting.zsh;
    };
    packages = with pkgs-stable; [
      zsh
      zsh
      bat
      eza
      fd
      zoxide
      yazi
    ];
  };
}
