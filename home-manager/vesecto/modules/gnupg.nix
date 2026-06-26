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
  # Route GnuPG's scdaemon through pcscd instead of its built-in CCID driver.
  #
  # The YubiKey exposes a single USB CCID interface. scdaemon's internal CCID
  # driver and pcscd (enabled for `ykman`, see modules/common/packages) each
  # try to claim that interface exclusively, so whichever grabs it first locks
  # the other out. The symptom is gpg signing intermittently failing with
  # "Please insert the card with serial number ...".
  #
  # `disable-ccid` makes scdaemon access the card via pcscd, so pcscd is the
  # single arbiter and gpg signing + ykman coexist without manually killing
  # scdaemon. `pcsc-shared` is intentionally NOT set: it is unnecessary here
  # (ykman works while scdaemon is running) and degrades PIN caching.
  home.file.".gnupg/scdaemon.conf".text = ''
    disable-ccid
  '';
}
