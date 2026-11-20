#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitLab: vesecky.tomas
{
  pkgs,
  lib,
  profile,
}: let
  homeFiles = "${profile.config.home.activationPackage}/home-files";
  # Only plugin-copy snippets run; full activation needs a Nix daemon and systemd.
  copiedPlugins = [
    "copyGraphifyPlugin"
    "copyGsdCorePluginEntry"
    "copySessionListAllPlugin"
    "installOmoPlugin"
  ];
  activationText =
    lib.concatMapStrings
    (name: profile.config.home.activation.${name}.data)
    copiedPlugins;

  # MCP command paths are plain strings in opencode.json; nothing else pulls their derivations into the closure.
  mcpCommandPaths =
    lib.flatten
    (lib.mapAttrsToList (_: s: s.command or []) profile.config.programs.opencode.settings.mcp);

  # Baked seed evaluates home files and plugin copies; path mistakes fail the build.
  seed = pkgs.runCommand "opencode-sandbox-seed" {} ''
    export HOME="$out"
    cp -a ${homeFiles}/. "$HOME"/
    chmod -R u+w "$HOME"
    run() { "$@"; }
    ${activationText}
    # Assertions: every required artifact must exist in the seed.
    test -f "$HOME/.config/opencode/plugins/graphify/plugin.js" \
      || { echo "seed: graphify plugin.js missing" >&2; exit 1; }
    test -f "$HOME/.config/opencode/plugins/gsd-core.js" \
      || { echo "seed: gsd-core.js missing" >&2; exit 1; }
    test -f "$HOME/.config/opencode/plugins/session-list-all/plugin.js" \
      || { echo "seed: session-list-all plugin.js missing" >&2; exit 1; }
    test -d "$HOME/.config/opencode/node_modules/oh-my-openagent" \
      || { echo "seed: oh-my-openagent missing" >&2; exit 1; }
    test -f "$HOME/.config/opencode/opencode.json" \
      || { echo "seed: opencode.json missing" >&2; exit 1; }
  '';

  # opencode-runtime tools that the sandbox shell must be able to find
  runtimeBins = [
    pkgs.coreutils
    pkgs.bash
    pkgs.gnugrep
    pkgs.gnused
    pkgs.findutils
    pkgs.diffutils
    pkgs.git
    pkgs.curl
    pkgs.gnutar
    pkgs.gzip
    pkgs.which
  ];

  root = pkgs.runCommand "opencode-sandbox-root" {} ''
    mkdir -p $out/bin $out/etc/ssl/certs $out/home/vesecto
    mkdir -p "$out/tmp"

    # /bin symlinks for every binary the sandbox needs at startup.
    for pkg in ${lib.concatStringsSep " " runtimeBins}; do
      for b in "$pkg"/bin/*; do
        [ -e "$b" ] && ln -sfn "$b" "$out/bin/$(basename "$b")"
      done
    done
    ln -sfn ${pkgs.bash}/bin/bash $out/bin/sh

    # Minimal passwd/group so uid 1000 resolves to a name.
    printf 'root:x:0:0:root:/root:/bin/sh\nvesecto:x:1000:100:vesecto:/home/vesecto:/bin/bash\n' > $out/etc/passwd
    printf 'root:x:0:\nvesecto:x:100:\n' > $out/etc/group

    # Docker skips /etc/hosts management in host network mode, and the image ships none.
    printf '127.0.0.1 localhost\n::1 localhost\n' > $out/etc/hosts

    # CA certificates + iana-etc for outbound TLS (MCP servers, npm, etc.).
    ln -s ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt $out/etc/ssl/certs/ca-bundle.crt
    ln -s ${pkgs.iana-etc}/etc/protocols $out/etc/protocols
    ln -s ${pkgs.iana-etc}/etc/services $out/etc/services

    # Force closure inclusion of these derivations.
    ln -s ${profile.config.home.path} $out/home-path
    ln -s ${seed} $out/sandbox-seed

    # MCP command paths are strings in opencode.json; symlink them so the closure carries them.
    mkdir -p $out/mcp-closure
    i=0
    for p in ${lib.concatStringsSep " " mcpCommandPaths}; do
      i=$((i + 1))
      ln -s "$p" "$out/mcp-closure/$i"
    done
  '';

  entrypoint = pkgs.writeShellApplication {
    name = "opencode-sandbox-entrypoint";
    extraShellCheckFlags = ["--external-sources"];
    runtimeInputs = [pkgs.coreutils];
    text = ''
      export HOME="''${HOME:-/home/vesecto}"
      mkdir -p "$HOME" /tmp
      install -d -m 1777 /tmp/opencode
      # Refresh managed files while retaining runtime state and writable symlinks.
      cp -a --no-preserve=mode,ownership,timestamps /sandbox-seed/. "$HOME"/
      # Ensure the per-sandbox writable state dirs exist.
      for d in "$HOME/.config" "$HOME/.config/opencode" \
               "$HOME/.local/share" "$HOME/.local/share/opencode" \
               "$HOME/.omo"; do
        mkdir -p "$d"
      done
      # shellcheck source=${profile.config.home.path}/etc/profile.d/hm-session-vars.sh
      . /home-path/etc/profile.d/hm-session-vars.sh
      exec "$@"
    '';
  };
in
  pkgs.dockerTools.streamLayeredImage {
    name = "localhost/opencode-sandbox";
    # A content-derived tag prevents stale latest-tag reuse.
    tag = null;
    contents = root;

    config = {
      Env = [
        "HOME=/home/vesecto"
        "PATH=/home-path/bin:/bin"
        "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
        "SSL_CERT_DIR=${pkgs.cacert}/etc/ssl/certs"
        "TERM=xterm-256color"
      ];
      Entrypoint = [
        "${entrypoint}/bin/opencode-sandbox-entrypoint"
      ];
      Cmd = ["opencode"];
      WorkingDir = "/home/vesecto";
      Labels."org.opencontainers.image.title" = "opencode-sandbox";
    };
  }
