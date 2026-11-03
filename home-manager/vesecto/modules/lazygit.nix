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
  programs.lazygit = {
    enable = true;
    shellWrapperName = "lg";
    enableZshIntegration = true;
    # Catppuccin mocha inlined: its lazygit port still ships pre-0.66 keys, and lazygit's auto-migration dies writing back to the read-only store path it puts in LG_CONFIG_FILE.
    settings.gui.theme = {
      activeBorderColor = ["#a6e3a1" "bold"];
      inactiveBorderColor = ["#a6adc8"];
      optionsTextColor = ["#89b4fa"];
      selectedLineBgColor = ["#313244"];
      inactiveViewSelectedLineBgColor = ["#6c7086"];
      cherryPickedCommitBgColor = ["#45475a"];
      cherryPickedCommitFgColor = ["#a6e3a1"];
      markedBaseCommitFgColor = ["#89b4fa"];
      markedBaseCommitBgColor = ["#f9e2af"];
      unstagedChangesColor = ["#f38ba8"];
      defaultFgColor = ["#cdd6f4"];
      searchingActiveBorderColor = ["#f9e2af"];
      authorColors."*" = "#b4befe";
    };
  };
}
