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

A **sidecar pin bump builds clean whatever you write in it** — the version is a string the build never resolves, and `installOmniroute` swallows a failed `npm install` to keep the previous version — so the build is no gate there: verify the activated artifact (`systemctl --user show omniroute.service -p ExecStart`) or let `nixos-run`'s update action pre-flight the pins.

## Commits

- `nixos-run` auto-generates messages: `<hostname>: Gen N`, `Home-manager <hostname>: Gen N`, `Update lockfiles`.
- Commits are GPG-signed via Yubikey (physical touch). Do not commit unless asked.

## Gotchas

- **Pinned inputs are bumped by `nixos-run`'s update action, not by hand:** `flake.lock` is the sole pin for `oh-my-openagent` and `graphify-src` (no `rev` lives in `flake.nix`), and `librewolf-bin.json`, `codegraph.json`, `tock.json` and `plugins/npm-plugins.json` (omniroute plus the opencode npm plugins) carry sidecar pins — the update action moves all of them for you.
- `.omo/`, `build/`, `result`, `__pycache__` are git-ignored.
- Bumping or patching `oh-my-openagent` (`plugins/oh-my-openagent/`, its `*-bun.lock`, `strip-senpi.py`) → read `docs/gotchas/oh-my-openagent.md`.
- Bumping `graphify-src` or editing `upstreamGraphifyAgentsMdSha256` → read `docs/gotchas/graphify.md`.
- OmniRoute or opencode config (`chains.json`, `omo.jsonc`, `plugins/omniroute/`, MCP `status=failed`, provider/500 errors) → read `docs/gotchas/omniroute.md`.
- Monitors, KVM or mouse (`modules/common/autorandr.nix`, `modules/common/gaming-mouse.nix`) → read `docs/gotchas/hardware.md`.
- Decrypting with gpg, `~/.gnupg/`, or `modules/api_keys/` secrets → read `docs/gotchas/gnupg-secrets.md`.
- Adding CI, a pre-commit hook or a `flake.nix` `checks` output → read `docs/gotchas/repo-guardrails.md` first (deliberately absent).
