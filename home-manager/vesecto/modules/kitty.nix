#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
{...}: {
  programs.kitty = {
    enable = true;
    shellIntegration = {
      mode = "no-cursor";
      enableZshIntegration = true;
    };
    font = {
      name = "Hack Nerd Font Mono";
      package = null;
      size = 10.0;
    };
    settings = {
      enable_audio_bell = false;
      background_opacity = 0.80;
      cursor_shape = "block";
      shell_integration = "no-cursor";
    };
    extraConfig = ''term xterm-256color'';
  };
  catppuccin.kitty = {
    enable = true;
    flavor = "mocha";
  };
}
