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
  programs.ssh.matchBlocks = {
    ebie = {
      user = "root";
      hostname = "ebie.is.cvut.cz";
      forwardAgent = true;
      localForwards = [
        {
          host = {
            address = "dv1";
            port = 5432;
          };
          bind.port = 5431;
        }
        {
          host = {
            address = "dv1";
            port = 22;
          };
          bind.port = 2221;
        }
        {
          host = {
            address = "dv2";
            port = 22;
          };
          bind.port = 2222;
        }
        {
          host = {
            address = "dv3";
            port = 22;
          };
          bind.port = 2223;
        }
        {
          host = {
            address = "dv4";
            port = 22;
          };
          bind.port = 2224;
        }
        {
          host = {
            address = "dv2";
            port = 8080;
          };
          bind.port = 8081;
        }
        {
          host = {
            address = "dv2";
            port = 8008;
          };
          bind.port = 8008;
        }
        {
          host = {
            address = "dv5";
            port = 5433;
          };
          bind.port = 5430;
        }
        {
          host = {
            address = "dv5";
            port = 5434;
          };
          bind.port = 5434;
        }
        {
          host = {
            address = "dv5";
            port = 5435;
          };
          bind.port = 5435;
        }
      ];
    };
  };
}
