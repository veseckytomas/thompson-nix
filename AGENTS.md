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

- **Pinned inputs are bumped by `nixos-run`'s update action, not by hand:** `flake.lock` is the sole pin for `oh-my-openagent` and `graphify-src` (no `rev` lives in `flake.nix`), and `librewolf-bin.json`, `codegraph.json` and `tock.json` carry sidecar pins — the update action moves all of them for you.
- **`oh-my-openagent` bumps are build-gated:** the gate is a candidate-lock transaction — the update action resolves the `dev` tip into a candidate `flake.lock` and promotes it over the live lock only if the package builds against it, so a rejected bump never moves the live lock and there is nothing to roll back; the regenerated `*-bun.nix` and `*-bun.lock` are the only artifacts written in place, so that pair gets backed up and restored together — restoring either alone desynchronises them. A rejected bump means upstream moved code a patch is anchored to — reconcile the patches in `home-manager/vesecto/modules/opencode/plugins/oh-my-openagent/`. The rejected `dev` tip is then memoised to `$XDG_STATE_HOME/nixos-run/oh-my-openagent-rejected-rev` and skipped on later runs, so a drifted patch set costs one failed build rather than a multi-minute refetch every update; a newer tip retries automatically, and deleting that file forces a retry of the same one.
- **`oh-my-openagent-bun.lock` is generated, never hand-edited, and never upstream's own lock:** upstream resolves `@code-yeongyu/senpi*`, whose registry manifests the offline bun2nix cache does not carry, so an unmodified lock fails the sandboxed install. The update action derives it by running the shipped `strip-senpi.py` (8 declarations across 4 manifests) and resolving **with upstream's `bun.lock` left in place as the basis** — deleting it first makes bun re-resolve every semver range and emit `lockfileVersion: 2`, which the gate rejects. `postPatch` copies this lock over upstream's, so the lock and the build tree must be stripped identically or bun discards the lock and tries to reach the network. The arity transform that feeds bun2nix runs on an ephemeral copy only; the shipped lock keeps its `integrity` field.
- **`oh-my-openagent` patches must fail loudly:** every upstream edit is a `.patch` in the `patches` list or a `substituteInPlace --replace-fail` in `postPatch`. Never use bare `sed`/`perl` there — a drifted anchor would silently no-op and quietly drop the fix (this already happened once to the symlinked-skills loader).
- **Only patch what is reachable — 7 fallback patches were dropped because both gates are off.** `runtime_fallback.enabled` is `false` and `model_fallback` is omitted (`?? false`), so `hooks/runtime-fallback/*` (`chat-message-handler.ts` returns at `if (!config.enabled)`) and `hooks/model-fallback/*` never execute; patches there are dead code that still costs anchor drift on every bump. Dropped: the quota-reached patterns, `next-fallback-skip-unserved-provider`, `agent-resolver-preserve-subagent-name`, both `chat-message-handler-*` (they are a pair — `internal-agents` calls `areRuntimeModelsEquivalent`, which `variant-aware-model` supplies), and both `*-snapshot-order` fixes. Recover them **before** flipping either flag on, or you silently lose quota-triggered fallback and two stale-snapshot bug fixes — five are at `HEAD~` under their old names, but `next-fallback-skip-unserved-provider` and the quota-reached patch were never committed, so they survive **only** as `refs/dropped-patches/*` (`git cat-file -p refs/dropped-patches/<name> > x.patch`); those refs are what keeps the blobs from being gc'd, so never delete them without restoring the content first. The three survivors are reachable: `skills-loader-accept-symlinked-skills` (home-manager ships ~99 skill `.md` files as symlinks, which upstream's *files* filter rejects — its *directory* filter already accepts symlinks, so the two look redundant and are not), `fallback-chain-honour-empty-optout` (live and ungated via `delegate-task/category-resolver.ts`, which `buildFallbackChainFromModels` reaches for the 8 configured categories), and `build-nodes-nix-profile` (build-time). Judge reachability by tracing the gate, never by the patch name.
- **`graphify-src` tracks only the newest `v0.9.x` tag — never `main` or `v1.x`:** those dropped the root `uv.lock` that `uv2nix.loadWorkspace` requires, so following them breaks the build. The bump runs behind the same candidate-lock gate with three pure checks: a `nix eval` of the generated `opencode/AGENTS.md` text (the upstream `agents-md.md` sha256 guard is lazy, so only evaluating that text forces it — a build-only gate would silently miss content drift) plus `nix build`s of the `graphify` package and the `opencode/skills/graphify` source. A rejected bump means upstream changed `graphify/always_on/agents-md.md` — reconcile `upstreamGraphifyAgentsMdSha256` in `home-manager/vesecto/modules/opencode/default.nix` — or changed the uv2nix workspace layout.
- **OmniRoute chains carry two invariants:** every chain in `chains.json` ends with `ctu/vic/GLM-5.3-Flash` (the unmetered self-hosted last resort, documented in the VPN-only wiki at `https://gitlab.dev1/ppsr-26/ai-coding/lokalni-ai/-/wikis/home` — `strategy` is `priority`, so keep it last), and `contextCeiling` in `providers/omniroute.nix` caps every advertised window at 250k to avoid context rot. `limit.context` is `min(member floor, ceiling)`, so the clamp only lowers — `quick-chain` stays at 128k because `litellm/mini` is genuinely that small. Adding a chain member needs a `model-limits.json` entry too, or the eval throws by design.
- **`omo.jsonc` is a read-only store symlink, so its `_migrations` list must name every upstream migration id — including the ones that are no-ops for us.** The loader reads user config only from `~/.omo/omo.jsonc` (`detectUserOmoJsonPath`), and a missing marker re-arms the matching migration. For `mode: "replace-target"` plans `legacySourcesExist` is just `existsSync(targetPath)`, so the config's own presence arms them, and the write then hits `assertConfigPathIsSafe` → `Refusing to edit symlinked omo config`, which surfaces as a `[config-migration]` warning at every startup. Four of the five are additionally gated by a `shouldRun` that our already-canonical config fails, but `2026-08-reasoning-unification` has **no `shouldRun` at all** — it fires purely on marker absence even though its transform changes nothing here (we set none of `reasoning`/`variant`/`reasoningEffort`/`thinking`). Judge each id by tracing its gate in the shipped bundle, never by whether the migration sounds relevant; on a bump, diff the plan list and add any new id. A dropped-marker regression is silent in the build and only shows up as every agent falling back to opencode's default model, because the failed load yields `DEFAULT_RAW_CONFIG` (`{agents:{},categories:{}}`).
- **`omo.jsonc` uses `models` (upstream folded `model`+`fallback_models` into it; `models[0]` is the primary, anything past it is dead since `[opencode].runtime_fallback.enabled` is `false`) — and entries must be ids opencode exposes (`omniroute/<chain>`), never gateway-internal prefixes like `ctu/` or `gh/`. Last-resort routing goes at the tail of a chain in `chains.json`. Upstream rejects the old `fallback_models` key outright now (unknown key → TUI shows "config invalid - run doctor"), so never re-add it.**
- **OmniRoute per-provider concurrency caps are Nix-provisioned, not dashboard state:** `plugins/omniroute/connection-caps.{nix,sh}` sets `provider_connections.max_concurrent=4` on the e-infra `litellm` connection before every gateway start, so `executeTargetGates` skips a full litellm pool and the priority chain advances to the next member instead of queueing. The cap is identified by `json_extract(provider_specific_data,'$.prefix')='litellm'`, and a manual dashboard edit of this value is stomped the next time `omniroute-connection-caps` runs — normally on the next `omniroute.service` start — because Nix is the source of truth; the gateway itself reads the cap per request, so no gateway restart is needed once the DB is written. The `ctu` connection intentionally stays uncapped (NULL).
- **opencode provider/500 errors → query OmniRoute `call_logs`, not journald:** the gateway only logs service start/fatal to the journal; per-call failures live in `~/.local/share/omniroute/data/storage.sqlite` (queries + `omniroute logs/health` shorthands in the repo `README.md` Diagnostics section).
- **Never call `gpg --decrypt` directly — use `gpg-decrypt-hardened`** (`home-manager/vesecto/modules/gnupg/`). A keyboxd that dies by SIGKILL leaves a dotlock naming a PID the kernel later recycles, and GnuPG only clears a lock whose PID is *dead*, so a recycled PID wedges every decrypt for 10s and then lies with `No secret key`. The wrapper classifies by liveness (`/proc/<pid>/comm != keyboxd`), not by link count. Default `--pinentry error`; use `--pinentry ask` only for Yubikey-gated blobs.
- **`~/.gnupg/common.conf` is home-manager-managed** (`gnupg/common-conf.nix`). Editing it by hand is reverted on the next switch, and a pre-existing unmanaged copy blocks activation — move it aside first.
- Secrets are GPG-encrypted blobs committed as ciphertext in `home-manager/vesecto/modules/api_keys/*.gpg`, decrypted only at consume time — there is no git-crypt in this repo. SSH/GPG keys and rclone/thunderbird configs are added manually post-install (see `README.md`).
- **The autorandr path is split across repo and nixpkgs, and needs `--force` to cure blank MST sinks:** nixpkgs' `services.autorandr` ships `/etc/udev/rules.d/40-monitor-hotplug.rules` (`ACTION=="change"`) while `modules/common/autorandr.nix` adds the `add` rule — both start `autorandr.service`, which is exactly why that unit is neutralized (`ExecStart` = `true`) and real convergence runs through `autorandr-trigger.timer` → `autorandr-converge.service` instead; touching either file means auditing both. Behind the KVM a sink can return KMS-mode-matched with a dead MST stream, where plain `--change` exits `Config already loaded` and leaves the monitor dark, so the converge's terminal `--force` + OFF/ON payload kick is load-bearing. One blanked output per KVM switch is the accepted cost.
- **The G502's active DPI index is volatile:** on every USB re-enumeration (i.e. every KVM switch) the sensor drops to the flash default — previously 1000dpi vs. the wanted 400dpi, the "DPI too big" bug. `modules/common/gaming-mouse.nix` runs ratbagd persistently (upstream default is dbus-activate then die after 30s idle) and reasserts resolution 0 via a `SYSTEMD_WANTS`-triggered `g502-dpi.service`. The on-device flash default was also flipped to 400dpi, but that is runtime state, not repo state — a mouse firmware factory-reset re-opens the 2.5x default and the udev service is what catches it.
- `.omo/`, `build/`, `result`, `__pycache__` are git-ignored.
