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
# {pkgs, ...}: {
{pkgs, ...}: {
  services = {
    libinput.touchpad.naturalScrolling = true;
    acpid.enable = true;
  };
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    # The uwsm session ships unconditionally but withUWSM is off, so it would launch a uwsm that is not installed.
    package = pkgs.hyprland.overrideAttrs (old: {
      postInstall =
        (old.postInstall or "")
        + ''
          rm -f $out/share/wayland-sessions/hyprland-uwsm.desktop
        '';
      passthru = old.passthru // {providedSessions = ["hyprland"];};
    });
  };
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    xdgOpenUsePortal = true;
    # The hyprland module already adds its own portal built against our package; listing it again collides on the unit name.
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };
}
