# Oh My OpenAgent Bun Dependency Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Home Manager evaluation-time `bun.nix` generation with a checked-in dependency file and a one-command update helper.

**Architecture:** The Home Manager module keeps using the pinned `bun2nix` flake package, but it passes a repository-local generated `oh-my-openagent-bun.nix` file to `bun2nix.fetchBunDeps` instead of creating that file with `pkgs.runCommand`. A dedicated script refreshes the `oh-my-openagent` flake input and regenerates the vendored dependency file from the updated upstream `bun.lock`.

**Tech Stack:** Nix flakes, Home Manager modules, `bun2nix`, Bash.

---

## File Structure

- Modify `home-manager/vesecto/modules/opencode/plugins/oh-my-openagent.nix`: remove the IFD `pkgs.runCommand` block and point `fetchBunDeps` at a checked-in generated file.
- Create `home-manager/vesecto/modules/opencode/plugins/oh-my-openagent-bun.nix`: generated `bun2nix` dependency metadata for the current locked `oh-my-openagent` input.
- Create `scripts/update-oh-my-openagent.sh`: update helper that updates only the `oh-my-openagent` input, regenerates dependency metadata, and fails without replacing the vendored file if generation fails.

## Task 1: Generate vendored dependency metadata

**Files:**
- Create: `home-manager/vesecto/modules/opencode/plugins/oh-my-openagent-bun.nix`

- [ ] **Step 1: Generate dependency metadata from the locked input**

Run:

```bash
tmpdir="$(mktemp -d)"
oh_my_openagent_path="$(nix eval --raw --impure --expr '(builtins.getFlake (toString ./. )).inputs.oh-my-openagent.outPath')"
bun2nix_rev="$(nix eval --raw --impure --expr '(builtins.getFlake (toString ./. )).inputs.bun2nix.rev')"
cp "$oh_my_openagent_path/bun.lock" "$tmpdir/bun.lock"
(
  cd "$tmpdir"
  nix run "github:nix-community/bun2nix/$bun2nix_rev" -- -o oh-my-openagent-bun.nix
)
cp "$tmpdir/oh-my-openagent-bun.nix" home-manager/vesecto/modules/opencode/plugins/oh-my-openagent-bun.nix
```

Expected: `home-manager/vesecto/modules/opencode/plugins/oh-my-openagent-bun.nix` exists and contains generated `bun2nix` metadata.

- [ ] **Step 2: Inspect the generated file**

Run:

```bash
test -s home-manager/vesecto/modules/opencode/plugins/oh-my-openagent-bun.nix
```

Expected: exit code `0`.

## Task 2: Remove evaluation-time generation from the Home Manager module

**Files:**
- Modify: `home-manager/vesecto/modules/opencode/plugins/oh-my-openagent.nix:17-35`

- [ ] **Step 1: Replace the IFD block with a local file reference**

Change the module header from:

```nix
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  bun2nix = inputs.bun2nix.packages.${system}.default;

  # Auto-generate bun.nix from upstream lockfile via IFD.
  # This regenerates automatically whenever inputs.oh-my-openagent updates,
  # so there is no manually-maintained fixed-output hash.
  bunNix = pkgs.runCommand "oh-my-openagent-bun.nix" {
    nativeBuildInputs = [ bun2nix ];
    preferLocalBuild = true;
    allowSubstitutes = false;
  } ''
    cp ${inputs.oh-my-openagent}/bun.lock .
    bun2nix -o $out
  '';

  bunDeps = bun2nix.fetchBunDeps {
    bunNix = bunNix;
  };
```

to:

```nix
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  bun2nix = inputs.bun2nix.packages.${system}.default;
  bunNix = ./oh-my-openagent-bun.nix;

  bunDeps = bun2nix.fetchBunDeps {
    inherit bunNix;
  };
```

Expected: no `pkgs.runCommand "oh-my-openagent-bun.nix"` remains in the file.

- [ ] **Step 2: Confirm the IFD removal**

Run:

```bash
grep -n 'oh-my-openagent-bun.nix\|runCommand' home-manager/vesecto/modules/opencode/plugins/oh-my-openagent.nix
```

Expected: output includes `bunNix = ./oh-my-openagent-bun.nix;` and does not include `runCommand`.

## Task 3: Add the update helper script

**Files:**
- Create: `scripts/update-oh-my-openagent.sh`

- [ ] **Step 1: Add a fail-fast regeneration script**

Create `scripts/update-oh-my-openagent.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
target="$repo_root/home-manager/vesecto/modules/opencode/plugins/oh-my-openagent-bun.nix"
tmpdir="$(mktemp -d)"

cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

cd "$repo_root"

nix flake lock --update-input oh-my-openagent

oh_my_openagent_path="$(nix eval --raw --impure --expr '(builtins.getFlake (toString ./. )).inputs.oh-my-openagent.outPath')"
bun2nix_rev="$(nix eval --raw --impure --expr '(builtins.getFlake (toString ./. )).inputs.bun2nix.rev')"
cp "$oh_my_openagent_path/bun.lock" "$tmpdir/bun.lock"

(
  cd "$tmpdir"
  nix run "github:nix-community/bun2nix/$bun2nix_rev" -- -o oh-my-openagent-bun.nix
)

install -m 0644 "$tmpdir/oh-my-openagent-bun.nix" "$target"

echo "Updated flake.lock and $target"
```

Expected: script exists and is readable.

- [ ] **Step 2: Make the script executable**

Run:

```bash
chmod +x scripts/update-oh-my-openagent.sh
```

Expected: `test -x scripts/update-oh-my-openagent.sh` exits `0`.

## Task 4: Verify the workflow

**Files:**
- Verify: `home-manager/vesecto/modules/opencode/plugins/oh-my-openagent.nix`
- Verify: `home-manager/vesecto/modules/opencode/plugins/oh-my-openagent-bun.nix`
- Verify: `scripts/update-oh-my-openagent.sh`

- [ ] **Step 1: Check shell syntax**

Run:

```bash
bash -n scripts/update-oh-my-openagent.sh
```

Expected: exit code `0`.

- [ ] **Step 2: Check Nix formatting/parsing on touched Nix files**

Run:

```bash
nix eval --expr 'builtins.parseDrvName "oh-my-openagent"'
```

Expected: exit code `0`; this confirms the local Nix evaluator is available before the Home Manager check.

- [ ] **Step 3: Evaluate Home Manager configuration**

Run:

```bash
home-manager build --flake .#"$(whoami)"
```

Expected: the build no longer fails while generating `oh-my-openagent-bun.nix` with `pkgs.runCommand`. If it fails later fetching package tarballs, record the new fixed-output dependency error separately; the IFD removal is still complete.

## Self-Review

- Spec coverage: Tasks cover the checked-in dependency file, Home Manager module change, update helper script, and verification.
- Placeholder scan: No `TBD`, `TODO`, or unspecified implementation steps remain.
- Consistency check: The generated file path is consistently `home-manager/vesecto/modules/opencode/plugins/oh-my-openagent-bun.nix`, and the script writes the same path consumed by the module.
