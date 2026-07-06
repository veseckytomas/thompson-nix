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
  # catppuccin/nix dunst ships a blue accent and needs services.dunst; drop-in forces mocha+mauve on the qtile-autostarted dunst.
  xdg.configFile."dunst/dunstrc.d/catppuccin-mocha-mauve.conf".text = ''
    [global]
    frame_color = "#cba6f7"
    separator_color = frame
    highlight = "#cba6f7"

    [urgency_low]
    background = "#1e1e2e"
    foreground = "#cdd6f4"

    [urgency_normal]
    background = "#1e1e2e"
    foreground = "#cdd6f4"

    [urgency_critical]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    frame_color = "#fab387"
  '';
}
