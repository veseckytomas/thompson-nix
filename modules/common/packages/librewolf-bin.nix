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
#
# Self-contained LibreWolf, built from the official upstream binary release
# (Codeberg generic package registry). Decoupled from the nixpkgs `librewolf`
# package, which is flagged unmaintained. Version + hash live in
# ./librewolf-bin.json and are bumped automatically by scripts/update.sh.
{
  lib,
  stdenv,
  fetchurl,
  wrapFirefox,
  wrapGAppsHook3,
  autoPatchelfHook,
  patchelfUnstable, # need --no-clobber-old-sections, see nixpkgs librewolf-bin
  alsa-lib,
  curl,
  dbus-glib,
  gtk3,
  libxtst,
  libva,
  pciutils,
  pipewire,
  adwaita-icon-theme,
}: let
  sources = lib.importJSON ./librewolf-bin.json;
  inherit (sources) version hash;

  binaryName = "librewolf";

  mozillaPlatforms = {
    x86_64-linux = "linux-x86_64";
    aarch64-linux = "linux-arm64";
  };
  throwSystem = throw "librewolf-bin: unsupported system: ${stdenv.hostPlatform.system}";
  arch = mozillaPlatforms.${stdenv.hostPlatform.system} or throwSystem;

  # Directory the browser is unpacked into; libName must match so the Firefox
  # wrapper can locate the binary and the bundled librewolf.cfg / policies.
  libName = "librewolf-${version}";

  unwrapped = stdenv.mkDerivation {
    pname = "librewolf-bin-unwrapped";
    inherit version;

    src = fetchurl {
      url = "https://codeberg.org/api/packages/librewolf/generic/librewolf/${version}/librewolf-${version}-${arch}-package.tar.xz";
      inherit hash;
    };

    nativeBuildInputs = [
      wrapGAppsHook3
      autoPatchelfHook
      patchelfUnstable
    ];

    buildInputs = [
      gtk3
      adwaita-icon-theme
      alsa-lib
      dbus-glib
      libxtst
    ];

    runtimeDependencies = [
      curl
      libva.out
      pciutils
    ];

    appendRunpaths = ["${pipewire}/lib"];

    # Firefox uses "relrhack" to manually process relocations from a fixed offset
    patchelfFlags = ["--no-clobber-old-sections"];

    installPhase = ''
      runHook preInstall

      mkdir -p $prefix/lib $out/bin
      cp -r . $prefix/lib/${libName}
      ln -s $prefix/lib/${libName}/librewolf $out/bin/${binaryName}
      # See: https://github.com/mozilla/policy-templates/blob/master/README.md
      mv $out/lib/${libName}/distribution/policies.json \
         $out/lib/${libName}/distribution/extra-policies.json

      runHook postInstall
    '';

    passthru = {
      inherit binaryName libName;
      applicationName = "LibreWolf";
      ffmpegSupport = true;
      gssSupport = true;
      inherit gtk3;
    };

    meta = {
      description = "Fork of Firefox, focused on privacy, security and freedom (upstream binary release)";
      homepage = "https://librewolf.net";
      license = lib.licenses.mpl20;
      platforms = builtins.attrNames mozillaPlatforms;
      mainProgram = "librewolf";
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    };
  };
in
  # Wrap with the standard Firefox wrapper so we get desktop integration,
  # library paths, ffmpeg/pipewire, and so the bundled LibreWolf privacy prefs
  # (librewolf.cfg) and policies are loaded. A wrapped package is also required
  # for home-manager's programs.librewolf to reconfigure it via .override.
  wrapFirefox unwrapped {
    extraPrefsFiles = ["${unwrapped}/lib/${libName}/librewolf.cfg"];
    extraPoliciesFiles = ["${unwrapped}/lib/${libName}/distribution/extra-policies.json"];
  }
