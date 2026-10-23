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

The repo has **no automated guardrail**: no pre-commit hook, no CI (no `.github/`, no `.gitlab-ci.yml`), and no `checks` output in `flake.nix`. `alejandra` and `statix` are declared as the formatter and linter in `AGENTS.md`, but nothing enforces them — a human or an agent that forgets to run them produces a commit nobody flags. The only enforced gate is whatever `nixos-rebuild build` / `home-manager build` happens to evaluate, and that gate is weaker than it looks: files copied at activation (see `home-manager/vesecto/modules/opencode/plugins/session-list-all/default.nix`) and sidecar pin bumps are not evaluated by a build at all unless something forces them.

## Deliberately not fixed

Adding `checks.x86_64-linux` + a hook was considered and **declined** during the 2026-10-23 retro — recorded here rather than acted on. Revisit when a lint-level mistake actually lands in a commit.

What it would take, if revisited:

- `checks.${system}.lint` in `flake.nix` running `alejandra --check .` and `statix check .` over the tree.
- Wiring it into `nixos-run` (or a `git-hooks.nix` pre-commit hook) so it runs without being remembered.
- Per-file build gates for anything activation copies rather than builds — the `node --check` wrapper in `plugins/session-list-all/default.nix` is the pattern to copy.

With `nix flake check` wired up, the "Formatter / Linter" lines in `AGENTS.md` collapse to a single pointer at that command.
