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
{
  lib,
  buildGoModule,
  src,
  version,
}: let
  sources = lib.importJSON ./tock.json;
in
  buildGoModule {
    pname = "tock";
    inherit src version;

    # Go dep hash, not the source pin; nixos-run's Update rewrites tock.json on a rev bump.
    inherit (sources) vendorHash;

    # cmd/tock only: the module root pulls fyne.io/systray, which is macOS-only.
    subPackages = ["cmd/tock"];

    # Upstream injects the version via goreleaser, so a plain build reports "dev".
    ldflags = [
      "-s"
      "-w"
      "-X github.com/kriuchkov/tock/internal/app/commands.version=${version}"
    ];

    meta = {
      description = "Time tracking tool for the command line with an interactive TUI";
      homepage = "https://github.com/kriuchkov/tock";
      license = lib.licenses.gpl3Only;
      platforms = lib.platforms.linux;
      mainProgram = "tock";
    };
  }
