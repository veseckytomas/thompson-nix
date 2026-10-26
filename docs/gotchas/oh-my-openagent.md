<!--
  ________
 /_  __/ /_  ____  ____ ___  ____  _________  ____
  / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
 / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
/_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
                         /_/
Tomáš Vesecký
Email: vesecky@proton.me
GitHub: veseckytomas
GitLab: vesecky.tomas
-->

# oh-my-openagent gotchas

Package lives in `home-manager/vesecto/modules/opencode/plugins/oh-my-openagent/`; its pin is `flake.lock` (see the pinned-inputs bullet in `AGENTS.md`).

## opencode is frozen at 1.x

**`opencode` does not come from `pkgs`:** omo is a V1 plugin and its V2 port is unfinished, so `nixpkgs-opencode` in `flake.nix` pins the package to the last nixpkgs channel commit carrying 1.x while the rest of the tree tracks unstable. Lift it — drop the input, restore `opencodeBase = pkgs.opencode` — only once an omo bump lands the V2 port (upstream `code-yeongyu/oh-my-openagent#9391`, plus the V2 compaction and MCP bugs `#10465` / `#10245`). The rev sits in the input URL, so `nixos-run`'s update action cannot move it: this pin is bumped by hand, against nixpkgs history, unlike every other pin in `AGENTS.md`. Prefer a rev the channel actually shipped — an intermediate nixpkgs commit builds opencode from source on every host.

## Bumps are build-gated

**`oh-my-openagent` bumps are build-gated:** the gate is a candidate-lock transaction — the update action resolves the `dev` tip into a candidate `flake.lock` and promotes it over the live lock only if the package builds against it, so a rejected bump never moves the live lock and there is nothing to roll back; the regenerated `*-bun.nix` and `*-bun.lock` are the only artifacts written in place, so that pair gets backed up and restored together — restoring either alone desynchronises them. A rejected bump means upstream moved code a patch is anchored to — reconcile the patches in `home-manager/vesecto/modules/opencode/plugins/oh-my-openagent/`. The rejected `dev` tip is then memoised to `$XDG_STATE_HOME/nixos-run/oh-my-openagent-rejected-rev` and skipped on later runs, so a drifted patch set costs one failed build rather than a multi-minute refetch every update; a newer tip retries automatically, and deleting that file forces a retry of the same one.

## The bun lock is generated

**`oh-my-openagent-bun.lock` is generated, never hand-edited, and never upstream's own lock:** upstream resolves `@code-yeongyu/senpi*`, whose registry manifests the offline bun2nix cache does not carry, so an unmodified lock fails the sandboxed install. The update action derives it by running the shipped `strip-senpi.py` (8 declarations across 4 manifests) and resolving **with upstream's `bun.lock` left in place as the basis** — deleting it first makes bun re-resolve every semver range and emit `lockfileVersion: 2`, which the gate rejects. `postPatch` copies this lock over upstream's, so the lock and the build tree must be stripped identically or bun discards the lock and tries to reach the network. The arity transform that feeds bun2nix runs on an ephemeral copy only; the shipped lock keeps its `integrity` field.

## Patches must fail loudly

**`oh-my-openagent` patches must fail loudly:** every upstream edit is a `.patch` in the `patches` list or a `substituteInPlace --replace-fail` in `postPatch`. Never use bare `sed`/`perl` there — a drifted anchor would silently no-op and quietly drop the fix (this already happened once to the symlinked-skills loader).

## Only patch what is reachable

**Only patch what is reachable — 7 fallback patches were dropped because both gates are off.** `runtime_fallback.enabled` is `false` and `model_fallback` is omitted (`?? false`), so `hooks/runtime-fallback/*` (`chat-message-handler.ts` returns at `if (!config.enabled)`) and `hooks/model-fallback/*` never execute; patches there are dead code that still costs anchor drift on every bump.

Dropped: the quota-reached patterns, `next-fallback-skip-unserved-provider`, `agent-resolver-preserve-subagent-name`, both `chat-message-handler-*` (they are a pair — `internal-agents` calls `areRuntimeModelsEquivalent`, which `variant-aware-model` supplies), and both `*-snapshot-order` fixes.

Recover them **before** flipping either flag on, or you silently lose quota-triggered fallback and two stale-snapshot bug fixes — five are at `HEAD~` under their old names, but `next-fallback-skip-unserved-provider` and the quota-reached patch were never committed, so they survive **only** as `refs/dropped-patches/*` (`git cat-file -p refs/dropped-patches/<name> > x.patch`); those refs are what keeps the blobs from being gc'd, so never delete them without restoring the content first.

The three survivors are reachable:

- `skills-loader-accept-symlinked-skills` (home-manager ships ~99 skill `.md` files as symlinks, which upstream's *files* filter rejects — its *directory* filter already accepts symlinks, so the two look redundant and are not),
- `fallback-chain-honour-empty-optout` (live and ungated via `delegate-task/category-resolver.ts`, which `buildFallbackChainFromModels` reaches for the 8 configured categories), and
- `build-nodes-nix-profile` (build-time).

Judge reachability by tracing the gate, never by the patch name.
