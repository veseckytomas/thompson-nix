# CodeGraph, packaged the Nix way.
#
# Upstream `@colbymchenry/codegraph` is a thin npm shim that pulls a
# platform-specific, "self-contained" bundle (esbuild-style optionalDependency).
# For linux-x64 that bundle ships:
#   - lib/dist        the actual JS (entrypoint lib/dist/bin/codegraph.js)
#   - lib/node_modules  its runtime deps (all pure JS / WASM, zero native .node)
#   - node            a prebuilt, generic-linux Node binary
#
# That prebuilt `node` is dynamically linked against /lib64/ld-linux-x86-64.so.2,
# which on NixOS is only a stub-ld -> the codegraph MCP server dies on spawn and
# opencode reports `codegraph MCP error -32000: Connection close`.
#
# Fix: keep upstream's vendored JS + node_modules verbatim (no dependency-
# resolution drift), throw the broken `node` away, and run the entrypoint with
# nixpkgs nodejs_24 instead. `--liftoff-only` mirrors upstream's own launcher
# (avoids a V8 turboshaft WASM Zone OOM when web-tree-sitter compiles grammars).
#
# oh-my-openagent resolves the codegraph command from $OMO_CODEGRAPH_BIN first,
# so pointing that env var at this package's bin overrides the broken provisioned
# bundle in ~/.omo/codegraph. See ../default.nix.
#
# Version + hash live in ./codegraph.json and are bumped automatically by the
# "Update" action in nixos-run (and scripts/update.sh). npm's per-version
# dist.integrity is already an SRI hash, so fetchurl consumes it directly.
{
  lib,
  stdenvNoCC,
  fetchurl,
  nodejs_24,
  makeWrapper,
}: let
  sources = lib.importJSON ./codegraph.json;
  inherit (sources) version hash;
in
  stdenvNoCC.mkDerivation {
    pname = "codegraph";
    inherit version;

    src = fetchurl {
      url = "https://registry.npmjs.org/@colbymchenry/codegraph-linux-x64/-/codegraph-linux-x64-${version}.tgz";
      inherit hash;
    };

    # npm tarballs unpack into ./package
    sourceRoot = "package";

    nativeBuildInputs = [makeWrapper];

    # Pure JS/WASM payload; nothing to compile. Deliberately drop the bundled
    # `node` binary and provide our own runtime via the wrapper.
    installPhase = ''
      runHook preInstall

      mkdir -p "$out/lib"
      cp -r lib/. "$out/lib/"

      makeWrapper ${lib.getExe nodejs_24} "$out/bin/codegraph" \
        --add-flags "--liftoff-only $out/lib/dist/bin/codegraph.js"

      runHook postInstall
    '';

    meta = {
      description = "Local-first code intelligence for AI agents (MCP), run under nixpkgs Node";
      homepage = "https://www.npmjs.com/package/@colbymchenry/codegraph";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux"];
      mainProgram = "codegraph";
    };
  }
