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
  # Unconfigured journald sizes itself at 10% of the filesystem, which is ~92G on this 922G root.
  services.journald.settings.Journal = {
    SystemMaxUse = "1G";
    SystemKeepFree = "2G";
    # Cap one archived file so a crash loop rotates instead of filling the whole budget.
    SystemMaxFileSize = "128M";
    MaxRetentionSec = "1month";
    # Bounded from the default 100 so a boot-time error flood cannot evict weeks of history.
    RateLimitBurst = 5000;
  };
}
