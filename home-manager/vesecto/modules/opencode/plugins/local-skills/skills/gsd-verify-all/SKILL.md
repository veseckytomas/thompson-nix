---
name: gsd-verify-all
disable-model-invocation: true
description: Run all four post-build quality gates (verify-work, add-tests, validate-phase, secure-phase) as subagents for phases that haven't run them yet.
---

# Verify All Gates

Run the four post-build quality **gates** for every phase that hasn't passed them yet. Each gate runs in a separate subagent so context stays clean between them.

## When to use

- After `/gsd-execute-phase`, when you want the full quality sweep before the MR.
- On a feature branch, inside a workstream.
- User types `verify-all` or asks to "run all verification" / "run all gates".

## Step 1 — Confirm workstream routing

```bash
gsd-tools query workstream.get
```

If no active workstream, set it:
```bash
gsd-tools query workstream.set <GSD_WORKSTREAM>
```

Parse `<GSD_WORKSTREAM>` from `.gsd-workstream` if needed.

## Step 2 — Find phases and their gate status

Read the workstream ROADMAP.md to get the phase list:

```bash
cat .planning/workstreams/<GSD_WORKSTREAM>/ROADMAP.md
```

Extract phase numbers (skip phase 999 — backlog).

For each phase, check which **gates** have already produced evidence:

| Gate | Evidence file (in phase dir) |
|---|---|
| verify-work | `VERIFICATION.md` |
| add-tests | any `test*` file or `*-test.*` / `*.test.*` file in the phase dir or codebase |
| validate-phase | `VALIDATION.md` |
| secure-phase | `SECURITY.md` |

Phase directory pattern: `.planning/workstreams/<ws>/phases/<N>-*/`

```bash
for phase_dir in .planning/workstreams/<GSD_WORKSTREAM>/phases/[0-9]*/; do
  phase=$(basename "$phase_dir" | cut -d- -f1)
  echo "Phase $phase:"
  for evidence in VERIFICATION.md VALIDATION.md SECURITY.md; do
    [ -f "$phase_dir/$evidence" ] && echo "  $evidence: present" || echo "  $evidence: MISSING"
  done
done
```

Only run gates whose evidence file is missing. Present the table to the user before proceeding.

## Step 3 — Run missing gates as subagents

Gate order within a phase (stop on failure):

1. **verify-work** — conversational UAT
2. **add-tests** — generates test files
3. **validate-phase** — Nyquist coverage audit
4. **secure-phase** — threat mitigation audit

For each phase with missing gates, spawn one subagent per gate (sequential within a phase, sequential across phases):

```
task(
  category="unspecified-high",
  prompt="Execute /gsd-<gate-name> for phase <N> in workstream <ws>.

Before starting:
1. Run: gsd-tools query workstream.set <ws>
2. Read the workflow file: ~/.config/opencode/gsd-core/workflows/<gate-workflow>.md
3. Follow the workflow steps. Pass --ws <ws> to every gsd-tools call.
4. Commit results as the workflow instructs.
5. Report exactly: PASS or FAIL, with a one-line summary of what was verified/found."
)
```

Gate → workflow mapping:

| Gate | Workflow file |
|---|---|
| verify-work | `verify-work.md` |
| add-tests | `add-tests.md` |
| validate-phase | `validate-phase.md` |
| secure-phase | `secure-phase.md` |

If a subagent reports **FAIL**, stop running gates for that phase. Record the failure. Continue to the next phase only if the user confirms (or if the skill was told to continue on failure).

**Completion criterion:** every phase either has all four gate evidence files present, or each missing gate was attempted and its result (pass/fail/skip) is recorded in the summary table below.

## Step 4 — Summary

Present:

```
Phase | verify-work | add-tests | validate-phase | secure-phase
------|-------------|-----------|----------------|-------------
1     | pass        | pass      | skip (no I/O)  | pass
2     | pass        | fail      | skipped        | skipped
3     | pass        | pass      | pass           | pass
```

Marks: `pass`, `fail`, `skip` (with reason), `—` (not run).

## Fallbacks

### No phases found

ROADMAP.md has no phases or phases dir is empty. Say so in one line. The user may need to run `/gsd-plan-phase` first.

### Workstream not set

`gsd-tools query workstream.get` returns null. Parse from `.gsd-workstream` or branch name, run `workstream.set`, verify with `config-path`.

### Subagent can't execute workflow

If a subagent reports it couldn't follow the workflow (file not found, permission error), check that gsd-core is installed (`~/.config/opencode/gsd-core/workflows/` exists). The workflow files are the same ones the main agent loads via `@` references in gsd command files — the subagent reads them directly.
