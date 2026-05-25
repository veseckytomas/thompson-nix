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
  programs.ssh.settings = {
    dv7 = {
      user = "vesecto1";
      hostname = "dv7.ds.prod.is.vic";
    };
    dv9 = {
      user = "vesecto1";
      hostname = "dv9.ds.test.is.vic";
    };
    ebie = {
      user = "root";
      hostname = "ebie.is.cvut.cz";
      forwardAgent = true;
      extraConfig = ''
        LocalForward 5431 dv1:5432
        LocalForward 2221 dv1:22
        LocalForward 2222 dv2:22
        LocalForward 8081 dv2:8080
        LocalForward 8008 dv2:8008
      '';
    };
  };
}
