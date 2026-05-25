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
    am1 = {
      user = "vesecto1~am1";
      hostname = "fit-workspaces.ksi.fit.cvut.cz";
      forwardAgent = true;
      extraConfig = ''
        LocalForward 8080 localhost:8080
      '';
    };
  };
}
