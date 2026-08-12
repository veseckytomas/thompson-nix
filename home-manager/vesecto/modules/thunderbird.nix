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
  # Prefs only: `programs.thunderbird` is deliberately NOT used, since declaring a
  # profile makes it own profiles.ini and rename the profile label.
  # Accounts, passwords and certificates stay manual (see README).
  home.file.".thunderbird/1hmdrmh5.default/user.js" = {
    force = true;
    # Microsoft's external-browser OAuth opens a short-lived IPv4 loopback
    # listener, then fails with "unable to connect" once it is gone; false
    # uses Thunderbird's in-app OAuth window and skips the redirect.
    text = ''
      user_pref("mailnews.oauth.useExternalBrowser", false);
    '';
  };
}
