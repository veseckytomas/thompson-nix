---
name: gsd-verify-all
disable-model-invocation: true
description: Run all five post-build quality gates (code-review, verify-work, add-tests, validate-phase, secure-phase) as subagents for phases that haven't run them yet.
---

# Verify All Gates

Run the five post-build quality **gates** for every phase that hasn't passed them yet. Each gate runs in a separate subagent so context stays clean between them.

## When to use

- After `/gsd-execute-phase`, when you want the full quality sweep before the MR.
- On a feature branch, in either project layout (workstream or flat).
- User types `verify-all` or asks to "run all verification" / "run all gates".

## Step 1 — Resolve the phase root

```bash
gsd-tools query workstream.get
```

Two layouts, and every path below depends on which one you are in. Resolve it first:

| `workstream.get` returns | Layout | `PHASE_ROOT` | `ROADMAP` |
|---|---|---|---|
| `{"active": "<ws>", …}` | workstream | `.planning/workstreams/<ws>/phases` | `.planning/workstreams/<ws>/ROADMAP.md` |
| `{"active": null, "mode": "flat"}` | flat | `.planning/phases` | `.planning/ROADMAP.md` |
| `{"active": null}`, mode not `flat` | workstream, unset | resolve first, below | — |

In **flat** mode there is no workstream to name: never run `workstream.set`, never pass `--ws`, and do not treat the null `active` as "unset". `workstream.set` on a flat project is a silent no-op — it returns `{"error": "not_found"}` with **exit 0** and leaves `active` null, so a caller checking only the exit status reads success, and every later `--ws` then resolves against a directory that does not exist.

Only in the third row is the workstream merely unset: parse it from `.gsd-workstream` or the branch name, `workstream.set <ws>`, verify with `config-path`.

Bind both once and use them for the rest of the run:

```bash
# flat
PHASE_ROOT=.planning/phases;                  ROADMAP=.planning/ROADMAP.md
# workstream
PHASE_ROOT=.planning/workstreams/<ws>/phases; ROADMAP=.planning/workstreams/<ws>/ROADMAP.md
```

## Step 2 — Find phases and their gate status

Read the ROADMAP for the phase list:

```bash
cat "$ROADMAP"
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

Phase directory pattern: `$PHASE_ROOT/<N>-*/`

```bash
for phase_dir in "$PHASE_ROOT"/[0-9]*/; do
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
  prompt="Execute /gsd-<gate-name> for phase <N>. Phase directory: <PHASE_ROOT>/<N>-*/

Before starting:
1. <routing line — see below>
2. Read the workflow file: ~/.config/opencode/gsd-core/workflows/<gate-workflow>.md
3. Follow the workflow steps.
4. Commit results as the workflow instructs. Never use --no-verify.
5. Report exactly: PASS, FAIL or SKIP, with a one-line summary of what was verified/found."
)
```

Line 1 differs by layout, and getting it wrong is the failure described in Step 1:

- **workstream:** `Run: gsd-tools query workstream.set <ws>, and pass --ws <ws> to every gsd-tools call.`
- **flat:** `This project is flat mode. Do NOT run workstream.set and do NOT pass --ws to any gsd-tools call.`

Always give the subagent the resolved phase directory. It cannot see your `PHASE_ROOT` shell variable, and a gate agent that guesses `.planning/workstreams/…` on a flat project writes its artifact to a path nobody reads.

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

Before reporting this, re-check `PHASE_ROOT` against Step 1 — a wrong root is indistinguishable from an empty one, and on a flat project the workstream path yields zero matches while the phases sit in `.planning/phases`. Confirm with `ls .planning/phases .planning/workstreams 2>&1`.

If the root is right and still empty, the ROADMAP has no phases. Say so in one line; the user may need `/gsd-plan-phase` first.

### Workstream not set

Only when `workstream.get` returns a null `active` **and** `mode` is not `flat`. Parse from `.gsd-workstream` or branch name, run `workstream.set`, verify with `config-path`. If `mode` is `flat`, this is not an error — go to the flat row in Step 1.

### Subagent can't execute workflow

If a subagent reports it couldn't follow the workflow (file not found, permission error), check that gsd-core is installed (`~/.config/opencode/gsd-core/workflows/` exists). The workflow files are the same ones the main agent loads via `@` references in gsd command files — the subagent reads them directly.
