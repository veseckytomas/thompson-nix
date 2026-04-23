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
{ pkgs, ... }: {
  programs.autorandr = {
    enable = true;
    hooks.postswitch = {
      "wacom-setup" = ''
        wacom_device="Wacom Intuos BT M Pen Pen (0x47803692)"
        wacom_pad="Wacom Intuos BT M Pad"

        # Set button map
        if ${pkgs.xorg.xinput}/bin/xinput list | grep -q "$wacom_pad"; then
          ${pkgs.xorg.xinput}/bin/xinput set-button-map "$wacom_pad" 17 18 19 4 5 6 7 20
        fi

        # Map to primary output
        PRIMARY_OUTPUT=$(${pkgs.xorg.xrandr}/bin/xrandr | grep " primary" | awk '{print $1}')
        if [ -n "$PRIMARY_OUTPUT" ]; then
          ${pkgs.xorg.xinput}/bin/xinput map-to-output "$wacom_device" "$PRIMARY_OUTPUT" 2>/dev/null || true
        fi
      '';
    };
  };
}
