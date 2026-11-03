---
name: bootstrap-repo
description: Bootstrap a new repository from scratch — generates flake.nix (Nix devShells for the chosen stack), .envrc (direnv), .editorconfig, .gitignore, LICENSE, README.md, .gitlab-ci.yml and AGENTS.md. Use when bootstrapping a new repo or converting an empty/practically-empty directory into a proper project.
---

# bootstrap-repo

Works in the **current directory**. Ask the user first (one question block, all at once):

1. **Project name** + one-sentence description (goes into the flake `description` and README title).
2. **Technologies** — free choice: nix / python / rust / shell / other. Multiple allowed. This drives the devShell and the gitignore.
3. **License** — free choice: MIT/ GPL 3.0 / other. If the user doesn't answer, GPL 3.0.
4. **Remote** — GitLab (gitlab.com) / GitHub / none. Drives CI and the README badge block.
5. **Remote path** - set as git origin

Do NOT ask what to ignore or what goes in the devShell — derive both from the answer to (2) using the tables below.

If the directory is not empty: list every file you would overwrite, get explicit confirmation before writing anything. Skip existing files unless told to overwrite.

After writing, print next steps for the user: `direnv allow`, `git init` + first commit (do not run git steps yourself unless the user explicitly asked for bootstrap-with-git), and `git remote add` if a remote was named.

## House conventions (non-negotiable)

- **Banner**: every generated code/config file opens with the ASCII banner below, verbatim, before any code. No trailing whitespace on banner lines. The template below is marker-free — prefix each line with a comment marker suited to the file's format, so the banner stays legal syntax: `#` for nix/yaml/gitignore/.envrc/.editorconfig/python/shell files, `//` for rust/go/c-family/ts, `--` for lua/sql, `<!-- ... -->` for markdown/html. `README.md` gets it as an HTML comment at the very top. No banner in `AGENTS.md` or other agent-instruction files (CLAUDE.md, GEMINI.md, …); none in `LICENSE` (license text untouched); none in `SKILL.md` (reserved — frontmatter first — not generated here).
- **Comments (STRICT)**: at most 1 line per comment; comment only non-obvious intent or gotchas; never narrate what the code does.
- **Authorship**: Tomáš Vesecký / vesecky@proton.me / GitHub: veseckytomas / GitLab: vesecky.tomas — goes in banner, LICENSE, README.

Banner template (verbatim, NO comment markers — add the right marker per file when writing it):

```
  ________
 /_  __/ /_  ____  ____ ___  ____  _________  ____
  / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
 / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
/_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
                         /_/
Tomáš Vesecký
Email: vesecky@proton.me
GitHub: veseckytomas
GitLab: vesecky.tomas
```

## Files to generate

Generate exactly these 8 files. Nothing else — no extra scaffolding, no placeholder dirs.

### 1. `flake.nix`

Start from `templates/flake.nix` in this skill directory. It contains stack blocks fenced by `# --- STACK: <name> ---` markers. Rules for the executor:

- Keep **only** the lines under the markers for the technologies the user named. Uncomment those lines.
- Delete all other stack lines **entirely** — commented leftovers are lint failures under `nixfmt --check` in `checks.lint`, so no commented-out alternatives survive.
- Delete every marker line (`# --- STACK: ... ---`) — scaffolding, never shipped.
- Fill in `description`.

Special case: "nix" as the user's technology = devShell gets `nil`/`nixfmt-rfc-style` etc. — author's choice; a plain empty-packages mkShell plus the `checks.lint` block (used by GitLab CI) is the nix-config-repo baseline.

### 2. `.envrc`

Banner (`#` marker), then exactly:

```sh
use flake
watch_file flake.nix
```

### 3. `.editorconfig`

Banner, then:

```editorconfig
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
indent_style = space
indent_size = 2
trim_trailing_whitespace = true

[*.md]
trim_trailing_whitespace = false

[{Makefile,*.mk}]
indent_style = tab
```

### 4. `.gitignore`

Banner (`#` marker). First two entries, immediately under the banner, **always**:

```gitignore
.omo/
.direnv/
```

Then `result` and `result-*` (always — every repo here is flake-backed even when no stack block is active).

Then, for each technology the user named, its section from this table, one pattern per line. Do not add sections for unnamed stacks.

| Stack  | Patterns                                                                                                                   |
| ------ | -------------------------------------------------------------------------------------------------------------------------- |
| python | `__pycache__/` `*.pyc` `.venv/` `dist/` `*.egg-info/` `.pytest_cache/` `.mypy_cache/` `.ruff_cache/` `.ipynb_checkpoints/` |
| rust   | `/target` `**/*.rs.bk`                                                                                                     |
| node   | `node_modules/` `dist/` `.npm/` `*.tsbuildinfo`                                                                            |
| shell  | `*.log`                                                                                                                    |

If two stacks both want `dist/`, write it once. Nothing else goes in — user adds project-specific lines themselves.

### 5. `LICENSE`

No banner. Use the license the user named (never assume a default); if the question went unanswered, GPL 3.0. For MIT: `Copyright (c) <year> Tomáš Vesecký` + full MIT text (standard OSI text, unmodified). For GPL 3.0 or any other named license: fetch the canonical text — do not paraphrase.

### 6. `README.md`

Banner as HTML comment at the very top. Then:

```markdown
# <project-name>

<one-sentence description>

## Development

Uses a Nix flake dev shell; run `direnv allow` once, tools come from the flake.

## License

<license-name> — see [LICENSE](LICENSE).
```

Add nothing else. The user will grow it.

### 7. `.gitlab-ci.yml`

Banner (`#` marker). Then the lint job — it unwraps to `checks.lint` from the flake:

```yaml
lint:
  image: nixos/nix:latest
  script:
    - nix --extra-experimental-features 'nix-command flakes' build --no-link .#checks.x86_64-linux.lint
```

If remote is GitHub-only, skip this file entirely (GitHub Actions is a separate ask).

### 8. `AGENTS.md`

No banner — written prose. Then:

```markdown
# AGENTS.md

<one-sentence description of the repo>.

## Comment policy

- Max 1 line per comment; comments capture non-obvious intent only.
- Every config file starts with the authorship banner, prefixed with that file's comment marker (copy the banner from any existing config file at the repo root).

## Layout

- `flake.nix` — Nix dev shell (`direnv allow`; or `nix develop`).
```

Keep it minimal; the layout section grows as code lands.
