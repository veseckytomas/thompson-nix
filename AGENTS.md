# AGENTS.md

Flake-based NixOS + Home Manager configuration for Tomáš Vesecký's machines (desktops, laptop, ARM/x86 servers, install/rescue ISOs).

## Comment policy (STRICT)

- **Max 1 line per comment.** No multi-line explanatory blocks.
- Comment **only** to capture a non-obvious idea, intent, or gotcha. If the code already says it, say nothing.
- Never narrate what the code does (`# Enable zsh` above `zsh.enable = true;` is acceptable only as a section label; prefer no comment).
- **Every config file MUST start with the ASCII banner authorship header below**, verbatim, before any code. This is an authorship convention exempt from the 1-line rule — it is not a code comment. Adapt the comment marker for non-`#` languages (Lua `--`); skip only formats without comments (JSON).
- Pre-existing multi-line comments may stay, but do not add new ones.

Required header (copy verbatim to the top of every file):

```
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
```

## Layout

- `flake.nix` — entry point. Defines `nixosConfigurations`, `homeConfigurations.vesecto`, and `packages.x86_64-linux.nixos-run`.
- `modules/` — system-level NixOS modules, grouped by domain (`audio`, `bootLoaders`, `common`, `loginManagers`, `networking`, `virtualisation`, `windowManagers`). Each dir's `default.nix` is a pure import aggregator.
- `modules/server.nix` — standalone server profile; pulls in Home Manager as a NixOS module using `home-manager/vesecto-server`.
- `home-manager/vesecto/` — standalone Home Manager config for the desktop user. `default.nix` → `home.nix` + `modules/`.
- `home-manager/vesecto-server/` — leaner Home Manager config used by servers.
- `hosts/<class>/<name>/` — per-machine config: `default.nix` imports `configuration.nix` + `hardware-configuration.nix` (+ host extras).

## Wiring

- `specialArgs` / `extraSpecialArgs` pass `inputs`, `username`, `system`, `pkgs-stable`, and (NixOS) `hostname`.
- Desktops/laptop track `nixpkgs-unstable`; servers track `nixpkgs-stable` (25.11). Use `pkgs-stable.<pkg>` to pin a stable package on an unstable host.
- `allowUnfree = true` is set globally.
- Add a new host: create `hosts/<class>/<name>/`, then register it under `nixosConfigurations` in `flake.nix`.
- Add a new module: drop the `.nix` file in the right domain dir and add it to that dir's `default.nix` `imports` list (alphabetical).

## Conventions

- **Formatter: `alejandra`** (Nix). Run it on every changed `.nix` file.
- **Linter: `statix`** (`empty_pattern` disabled).
- Other formatters in use: `stylua` (Lua), `isort`+`black` (Python), `beautysh` (shell), `taplo` (TOML).
- `default.nix` files stay pure aggregators: `{...}: { imports = [ ... ]; }`. Put logic in named leaf files, not in `default.nix`.
- Disable a module by commenting its line in the relevant `default.nix` (existing pattern) rather than deleting it.

## Build & verify

Use the `nixos-run` TUI (preferred) or direct commands:

```bash
nixos-run                              # interactive: rebuild / home-only / test / update / gc / iso / setup
nixos-rebuild build --flake .#         # build current host, no activation
home-manager build --flake .#vesecto   # build user config, no activation
```

After editing `.nix` files, verify with a **build** (`nixos-rebuild build` / `home-manager build`) — a clean build is the gate, not just `alejandra`/`statix`. Never `switch` on the user's behalf without being asked.

## Commits

- `nixos-run` auto-generates messages: `<hostname>: Gen N`, `Home-manager <hostname>: Gen N`, `Update lockfiles`.
- Commits are GPG-signed via Yubikey (physical touch). Do not commit unless asked.

## Gotchas

- **Pinned inputs are bumped by `nixos-run`'s update action, not by hand:** `oh-my-openagent`'s `rev` (in `flake.nix`), `librewolf-bin.json`, `codegraph.json` and `tock.json` all carry pins the update action moves for you.
- **`oh-my-openagent` bumps are build-gated:** the update action moves the pin to the `dev` tip, regenerates `*-bun.nix`, and keeps the result only if the package builds; on failure it restores `flake.nix`, `flake.lock` and `*-bun.nix` and leaves the old pin in place, so the rest of the update still lands. A rejected bump means upstream moved code a patch is anchored to — reconcile the patches in `home-manager/vesecto/modules/opencode/plugins/oh-my-openagent/`.
- **`oh-my-openagent` patches must fail loudly:** every upstream edit is a `.patch` in the `patches` list or a `substituteInPlace --replace-fail` in `postPatch`. Never use bare `sed`/`perl` there — a drifted anchor would silently no-op and quietly drop the fix (this already happened once to the symlinked-skills loader).
- **OmniRoute chains carry two invariants:** every chain in `chains.json` ends with `ctu/vic/GLM-5.3-Flash` (the unmetered self-hosted last resort, documented in the VPN-only wiki at `https://gitlab.dev1/ppsr-26/ai-coding/lokalni-ai/-/wikis/home` — `strategy` is `priority`, so keep it last), and `contextCeiling` in `providers/omniroute.nix` caps every advertised window at 250k to avoid context rot. `limit.context` is `min(member floor, ceiling)`, so the clamp only lowers — `quick-chain` stays at 128k because `litellm/mini` is genuinely that small. Adding a chain member needs a `model-limits.json` entry too, or the eval throws by design.
- **`fallback_models` in `oh-my-openagent.json` is inert — do not put gateway models there.** Its reactive fallback is gated on `runtime_fallback.enabled`, which is `false`. And entries must be ids opencode exposes (`omniroute/<chain>`), never gateway-internal prefixes like `ctu/` or `gh/`. Last-resort routing goes at the tail of a chain in `chains.json`.
- Secrets are GPG-encrypted blobs committed as ciphertext in `home-manager/vesecto/modules/api_keys/*.gpg`, decrypted only at consume time — there is no git-crypt in this repo. SSH/GPG keys and rclone/thunderbird configs are added manually post-install (see `README.md`).
- `.omo/`, `build/`, `result`, `__pycache__` are git-ignored.
