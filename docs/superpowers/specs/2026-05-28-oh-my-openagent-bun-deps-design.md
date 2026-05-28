# Oh My OpenAgent Bun Dependency Workflow Design

## Goal

Make Home Manager rebuilds reproducible and resilient by removing import-from-derivation generation of `bun.nix` from normal evaluation, while keeping `oh-my-openagent` updates a single explicit workflow.

## Current Problem

`home-manager/vesecto/modules/opencode/plugins/oh-my-openagent.nix` runs `bun2nix` during evaluation to generate `bun.nix` from the upstream `bun.lock`. That pulls `bun2nix` and its Rust dependencies into the Home Manager rebuild path. A crates.io fetch for `basic-toml-0.1.10` currently fails with HTTP 403 unless a cargo-like User-Agent is used, so a rebuild can fail before the actual plugin build starts.

## Chosen Approach

Use a hybrid vendored-dependencies workflow:

1. Store the generated dependency file in this repository, next to the plugin module.
2. Change the module to read that checked-in file instead of generating it with `pkgs.runCommand` during evaluation.
3. Add an update script that updates the `oh-my-openagent` flake input and regenerates the checked-in `bun.nix` from the new upstream `bun.lock` in the same operation.

This keeps ordinary rebuilds deterministic and network-free for dependency metadata, while updates remain automated rather than hand-edited.

## Components

- `home-manager/vesecto/modules/opencode/plugins/oh-my-openagent.nix`: consumes a local generated dependency file through `bun2nix.fetchBunDeps`.
- `home-manager/vesecto/modules/opencode/plugins/oh-my-openagent-bun.nix`: checked-in generated output from `bun2nix`.
- `scripts/update-oh-my-openagent.sh`: update helper that refreshes the flake input and regenerates the vendored dependency file.

## Data Flow

Normal rebuild:

1. Home Manager evaluates `oh-my-openagent.nix`.
2. The module imports the checked-in `oh-my-openagent-bun.nix` dependency file.
3. `bun2nix.fetchBunDeps` fetches package dependencies using stable metadata from the repo.
4. The plugin package and generated opencode config build as before.

Update workflow:

1. Run `scripts/update-oh-my-openagent.sh`.
2. The script runs `nix flake lock --update-input oh-my-openagent`.
3. The script copies the new upstream `bun.lock` to a temporary directory.
4. The script runs the pinned flake `bun2nix` package to generate `oh-my-openagent-bun.nix`.
5. The script rewrites generated workspace package paths from `./packages/...` to the locked `oh-my-openagent` source path, because the vendored file is stored outside the upstream repository root.
6. The user rebuilds Home Manager and commits the flake lock plus generated dependency file if verification passes.

## Error Handling

The update script fails fast on any command failure. It writes through a temporary file and only replaces the checked-in dependency file after successful generation, so failed updates do not corrupt the current working dependency file.

## Testing and Verification

Implementation verification should include:

- Run the update script or its regeneration path successfully.
- Evaluate or build the Home Manager path far enough to confirm `oh-my-openagent.nix` no longer creates `oh-my-openagent-bun.nix` via IFD.
- Run the relevant Home Manager build command if available in the repo workflow.

## Non-Goals

- Do not remove `bun2nix`; it is still needed to fetch dependencies and regenerate metadata.
- Do not change the plugin package build behavior beyond dependency metadata sourcing.
- Do not silently update dependencies during normal Home Manager rebuilds.
