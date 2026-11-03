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

# Repo guardrails

## State

The one guardrail is **`checks.x86_64-linux.lint`** in `flake.nix`: `alejandra --check` plus `statix check` over the `.nix` files, run by `nixos-run`'s rebuild and home actions (`lint_gate`) before the long build. `.gitlab-ci.yml` runs the same `lint` check on push, so a commit made outside `nixos-run` is still checked on GitLab; there is no local pre-commit hook.

Build it directly — `nix build .#checks.x86_64-linux.lint` — never via `nix flake check`, which evaluates every host and ISO to find it.

**Git-backed flake visibility:** new files must be staged with `git add <new-file>` before Nix evaluation or builds can see them; staging makes them visible without committing them. A harness added to `checks.lint` but left untracked fails the build with `No such file or directory`, not a lint error.

**Aborting a rebuild does not stop the build.** Ctrl-C kills the nix client; nix-daemon keeps compiling, and on a RAM-tight host the orphans go on competing with the desktop. After any aborted build check `pgrep -xc cc1plus` and kill survivors by exact PID (`pgrep -x`, then `kill` each) — a bare `pkill -f <pattern>` also matches the agent's own shell and kills the session.

**A harness that generates executable stubs cannot use `#!/usr/bin/env`:** `/usr/bin/env` does not exist in the nix sandbox, so the stubs fail only under `checks.lint`, never when run by hand. Resolve `bash_bin="$(command -v bash)"` and emit `printf '#!%s\n' "$bash_bin"`. The shebang on a harness's own first line is inert, since the gate invokes it as `bash <file>` — which is why the older harnesses carry `#!/usr/bin/env bash` safely and copying them misleads.

**A skill's bash is prose until an agent runs it.** `home-manager build` only checks that a `SKILL.md` exists, so a broken snippet ships and fails in some later session instead. The gate now `bash -n`s every ```` ```bash ```` fence under `plugins/local-skills/skills/`, substituting `<NAME>` placeholders first — without that, `cmd <PLACEHOLDER>` parses as a redirect and every fence is a false positive.

That catches syntax, never logic. **Run a new skill's bash against real data before shipping it, including the empty case** — a `gsd-verify-all` check for a bare `VERIFICATION.md` was valid bash that could never match the real `06-VERIFICATION.md`, passed the build, and silently re-ran every gate. The empty case is what surfaces unmatched-glob behavior, and these fences run under zsh as often as bash.

It also byte-checks the files `nixos-run` interpolates as data (`python3 -m compileall`, `shellcheck`) and runs the three hermetic harnesses (`verify-omniroute-resilience-readers-test.sh`, `diagnostics-cli-test.sh`, `resilience-defaults-test.sh`), whose gates would otherwise only fail mid-update. `shellcheck` skips the two shebang-less `writeShellApplication` fragments, which that builder already checks once assembled.

**The update gates run from the store, not the worktree.** `nixos-run`'s update action executes `update-*.sh` and `verify-*.py` from the `/nix/store` path baked in at build time (`default.nix`), and the OmniRoute preflight runs *before* `nh_os switch` — so editing one of those files changes nothing until a rebuild, and fixing a gate's own logic is inherently two-pass. Verify such a fix by running the script from the worktree by hand, then confirming the path the next build will bake in: `nix build .#nixos-run --no-link --print-out-paths`, then grep the result's `bin/nixos-run` for the interpolated store path.

Three things it deliberately does not cover:

- **Non-Nix formatters** (`stylua`, `isort`+`black`, `beautysh`, `taplo`): still manual.
- **`oh-my-openagent-bun.nix`**, excluded by path — bun2nix regenerates it unformatted on every bump.
- **Activation-copied files and sidecar pins**, which no build evaluates: the `node --check` wrapper in `home-manager/vesecto/modules/opencode/plugins/session-list-all/default.nix` is the per-file pattern to copy.

`lint_gate` warns and asks rather than aborting, so a failing lint cannot strand a half-applied machine; it is skipped outright on non-x86_64 hosts, where `checks` is undefined.
