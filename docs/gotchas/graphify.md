<!--
  ________
 /_  __/ /_  ____  ____ ___  ____  _________  ____
  / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
 / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
/_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
                         /_/
Tomáš Vesecký
Email: tomas@vesecky.net
GitHub: veseckytomas
GitLab: vesecky.tomas
-->

# graphify gotchas

## `graphify-src` pin

**`graphify-src` tracks only the newest `v0.9.x` tag — never `main` or `v1.x`:** those dropped the root `uv.lock` that `uv2nix.loadWorkspace` requires, so following them breaks the build. The bump runs behind the same candidate-lock gate with three pure checks: a `nix eval` of the generated `opencode/AGENTS.md` text (the upstream `agents-md.md` sha256 guard is lazy, so only evaluating that text forces it — a build-only gate would silently miss content drift) plus `nix build`s of the `graphify` package and the `opencode/skills/graphify` source. A rejected bump means upstream changed `graphify/always_on/agents-md.md` — reconcile `upstreamGraphifyAgentsMdSha256` in `home-manager/vesecto/modules/opencode/default.nix` — or changed the uv2nix workspace layout.
