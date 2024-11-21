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
  programs.kitty = {
    enable = true;
    themeFile = "Catppuccin-Mocha";
    font = {
      name = "Hack Nerd Font Mono";
      package = null;
      size = 10.0;
    };
    settings = {
      enable_audio_bell = false;
      # background_opacity = 0.85;
    };
    extraConfig = ''
      term xterm-256color
      background_opacity 0.85
    '';
  };
}
