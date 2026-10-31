---
name: gsd-verify-all
disable-model-invocation: true
description: Run all five post-build quality gates (code-review, verify-work, add-tests, validate-phase, secure-phase) as subagents for phases that haven't run them yet.
---

# Verify All Gates

Run the five post-build quality **gates** for every phase that hasn't passed them yet. Each gate runs in a separate subagent so context stays clean between them.

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

Evidence files are prefixed with the padded phase number, e.g. `06-REVIEW.md` — a bare `REVIEW.md` never matches.

| Gate | Evidence (in phase dir) |
|---|---|
| code-review | `<NN>-REVIEW.md` |
| verify-work | `<NN>-VERIFICATION.md` |
| add-tests | a `test(phase-<N>):` commit — it writes test files, not a phase-dir artifact |
| validate-phase | `<NN>-VALIDATION.md` |
| secure-phase | `<NN>-SECURITY.md` |

Phase directory pattern: `.planning/workstreams/<ws>/phases/<N>-*/`

```bash
for phase_dir in .planning/workstreams/<GSD_WORKSTREAM>/phases/[0-9]*/; do
  phase=$(basename "$phase_dir" | cut -d- -f1)
  echo "Phase $phase:"
  for gate_evidence in code-review:REVIEW verify-work:VERIFICATION validate-phase:VALIDATION secure-phase:SECURITY; do
    gate=${gate_evidence%%:*}
    suffix=${gate_evidence##*:}
    [ -f "$phase_dir/$phase-$suffix.md" ] && echo "  $gate: present" || echo "  $gate: MISSING"
  done
  git log --oneline --grep="^test(phase-$phase):" | head -1 | grep -q . \
    && echo "  add-tests: present" || echo "  add-tests: MISSING"
done
```

Only run gates whose evidence file is missing. Present the table to the user before proceeding.

## Step 3 — Run missing gates as subagents

Gate order within a phase (stop on failure):

1. **code-review** — bug and quality review of changed source
2. **verify-work** — conversational UAT
3. **add-tests** — generates test files
4. **validate-phase** — Nyquist coverage audit
5. **secure-phase** — threat mitigation audit

code-review runs first because GSD's own `workflow.code_review_point` defaults to `execute:post` — findings land before the verify gates interpret the code.

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
5. Report exactly: PASS, FAIL or SKIP, with a one-line summary of what was verified/found."
)
```

Gate → workflow mapping:

| Gate | Workflow file |
|---|---|
| code-review | `code-review.md` |
| verify-work | `verify-work.md` |
| add-tests | `add-tests.md` |
| validate-phase | `validate-phase.md` |
| secure-phase | `secure-phase.md` |

**code-review specifics.** This sweep is read-only: never pass `--fix` (it would let a subagent silently rewrite code). The workflow reports no PASS/FAIL — it writes `<NN>-REVIEW.md` with frontmatter `status` and counts `critical` / `warning` / `info`. Have the subagent map that to: `FAIL` when `critical > 0`, `SKIP (nothing reviewable)` when `status` is `skipped` — a docs-only phase, not a clean review — otherwise `PASS`, always appending the counts as `C/W/I`. If it prints `Code review skipped (code-review capability inactive)`, that is the `workflow.code_review` config gate — report `SKIP (capability inactive)`, not a failure.

If a subagent reports **FAIL**, stop running gates for that phase. Record the failure. Continue to the next phase only if the user confirms (or if the skill was told to continue on failure).

**Completion criterion:** every phase either has all five gate evidence files present, or each missing gate was attempted and its result (pass/fail/skip) is recorded in the summary table below.

## Step 4 — Summary

Present:

```
Phase | code-review   | verify-work | add-tests | validate-phase | secure-phase
------|---------------|-------------|-----------|----------------|-------------
1     | pass 0/2/5    | pass        | pass      | skip (no I/O)  | pass
2     | fail 1/0/3    | skipped     | skipped   | skipped        | skipped
3     | skip (off)    | pass        | pass      | pass           | pass
```

Marks: `pass`, `fail`, `skip` (with reason), `—` (not run). code-review appends its `critical/warning/info` counts.

## Fallbacks

### No phases found

ROADMAP.md has no phases or phases dir is empty. Say so in one line. The user may need to run `/gsd-plan-phase` first.

### Workstream not set

`gsd-tools query workstream.get` returns null. Parse from `.gsd-workstream` or branch name, run `workstream.set`, verify with `config-path`.

### Subagent can't execute workflow

If a subagent reports it couldn't follow the workflow (file not found, permission error), check that gsd-core is installed (`~/.config/opencode/gsd-core/workflows/` exists). The workflow files are the same ones the main agent loads via `@` references in gsd command files — the subagent reads them directly.
