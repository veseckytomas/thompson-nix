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
  dconf.settings = {
    "org/gnome/settings-daemon/plugins/media-keys" = {
      # Empty the default bindings if present
      calculator = ["''"];
      calculator-static = ["''"];

      # Set up custom keybinding
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };

    # Configure the custom keybinding
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Calculator";
      binding = "XF86Calculator";
      command = "sh -c 'if pidof qalculate-gtk > /dev/null; then kill $(pidof qalculate-gtk); else qalculate-gtk; fi'";
    };
  };
}
