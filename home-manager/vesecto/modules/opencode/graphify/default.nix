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
# graphifyy (CLIs `graphify` + `graphify-mcp`) built reproducibly from its uv
# workspace via uv2nix. The venv derivation carries /bin/graphify(-mcp).
{
  inputs,
  pkgs,
  lib ? pkgs.lib,
}: let
  python = pkgs.python312;

  workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = inputs.graphify-src;
  };

  # All runtime deps ship manylinux cp312 wheels; prefer them over sdists.
  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  # Runtime fixups for wheels autoPatchelfHook can't resolve unaided.
  pyprojectOverrides = _final: _prev: {};

  pythonSet =
    (pkgs.callPackage inputs.pyproject-nix.build.packages {
      inherit python;
    })
    .overrideScope (
      lib.composeManyExtensions [
        inputs.pyproject-build-systems.overlays.default
        overlay
        pyprojectOverrides
      ]
    );
in
  # Default deps + the [mcp] extra only (mcp + starlette); no heavy extras.
  pythonSet.mkVirtualEnv "graphifyy-env" {
    graphifyy = ["mcp"];
  }
