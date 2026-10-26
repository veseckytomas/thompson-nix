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

# Repo guardrails

## State

The one guardrail is **`checks.x86_64-linux.lint`** in `flake.nix`: `alejandra --check` plus `statix check` over the `.nix` files, run by `nixos-run`'s rebuild and home actions (`lint_gate`) before the long build. `.gitlab-ci.yml` runs the same `lint` check on push, so a commit made outside `nixos-run` is still checked on GitLab; there is no local pre-commit hook.

Build it directly — `nix build .#checks.x86_64-linux.lint` — never via `nix flake check`, which evaluates every host and ISO to find it.

Three things it deliberately does not cover:

- **Non-Nix formatters** (`stylua`, `isort`+`black`, `beautysh`, `taplo`): still manual.
- **`oh-my-openagent-bun.nix`**, excluded by path — bun2nix regenerates it unformatted on every bump.
- **Activation-copied files and sidecar pins**, which no build evaluates: the `node --check` wrapper in `home-manager/vesecto/modules/opencode/plugins/session-list-all/default.nix` is the per-file pattern to copy.

`lint_gate` warns and asks rather than aborting, so a failing lint cannot strand a half-applied machine; it is skipped outright on non-x86_64 hosts, where `checks` is undefined.
