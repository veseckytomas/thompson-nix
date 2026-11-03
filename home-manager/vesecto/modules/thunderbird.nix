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
{lib, ...}: let
  # Profile id differs per machine; a user.js in an unused profile dir is inert.
  profiles = ["63vjmbvh.default" "1hmdrmh5.default"];
in {
  # Prefs only: `programs.thunderbird` is deliberately NOT used, since declaring a
  # profile makes it own profiles.ini and rename the profile label.
  # Accounts, passwords and certificates stay manual (see README).
  home.file =
    lib.genAttrs (map (p: ".thunderbird/${p}/user.js") profiles)
    (_: {
      force = true;
      # Microsoft's external-browser OAuth binds an IPv4-only loopback listener that LibreWolf misses via ::1.
      text = ''
        user_pref("mailnews.oauth.useExternalBrowser", false);
      '';
    });
}
