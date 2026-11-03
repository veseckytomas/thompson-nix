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
  nix = {
    settings = {
      # Peak RAM tracks max-jobs x cores: each job forks that many compilers, so both are capped.
      max-jobs = 2;
      cores = 4;
    };

    # Yields the CPU to the desktop without idle's unbounded starvation of a long build.
    daemonCPUSchedPolicy = "batch";
    daemonIOSchedClass = "best-effort";
    daemonIOSchedPriority = 7;
  };

  # Builds are children of nix-daemon, so its cgroup caps bound every derivation it spawns.
  systemd.services.nix-daemon.serviceConfig = {
    # Percentages resolve against each host's own RAM, so this stays correct off this laptop.
    MemoryHigh = "60%";
    MemoryMax = "80%";
    # Without this, reclaim under vm.swappiness=150 pages straight into swap and thrashes anyway.
    MemorySwapMax = "25%";
    CPUWeight = 50;
    IOWeight = 50;
  };
}
