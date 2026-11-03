<!--
  ________
 /_  __/ /_  ____  ____ ___  ____  _________  ____
  / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
 / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
/_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
                         /_/
Tomáš Vesecký
Email: tomas@vesecky.net
GitHub: veseckytomas
GitLab: vesecky.tomas
-->

# Hardware gotchas (KVM, monitors, mouse)

## autorandr and MST sinks

**The autorandr path is split across repo and nixpkgs, and needs `--force` to cure blank MST sinks:** nixpkgs' `services.autorandr` ships `/etc/udev/rules.d/40-monitor-hotplug.rules` (`ACTION=="change"`) while `modules/common/autorandr.nix` adds the `add` rule — both start `autorandr.service`, which is exactly why that unit is neutralized (`ExecStart` = `true`) and real convergence runs through `autorandr-trigger.timer` → `autorandr-converge.service` instead; touching either file means auditing both. Behind the KVM a sink can return KMS-mode-matched with a dead MST stream, where plain `--change` exits `Config already loaded` and leaves the monitor dark, so the converge's terminal `--force` + OFF/ON payload kick is load-bearing. One blanked output per KVM switch is the accepted cost.

## G502 DPI

**The G502's active DPI index is volatile:** on every USB re-enumeration (i.e. every KVM switch) the sensor drops to the flash default — previously 1000dpi vs. the wanted 400dpi, the "DPI too big" bug. `modules/common/gaming-mouse.nix` runs ratbagd persistently (upstream default is dbus-activate then die after 30s idle) and reasserts resolution 0 via a `SYSTEMD_WANTS`-triggered `g502-dpi.service`. The on-device flash default was also flipped to 400dpi, but that is runtime state, not repo state — a mouse firmware factory-reset re-opens the 2.5x default and the udev service is what catches it.
