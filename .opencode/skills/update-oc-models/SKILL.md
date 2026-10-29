---
name: update-oc-models
description: Re-derive the OmniRoute chain members and model limits from upstream docs (omo, GSD) and the live model catalog. Use when bumping oh-my-openagent or get-shit-done-redux, when a provider adds or drops models, or when chains.json / model-limits.json drift from upstream.
---

# update-oc-models

Rewrites two files from upstream documentation plus the live catalog:

- `home-manager/vesecto/modules/opencode/plugins/omniroute/chains.json`
- `home-manager/vesecto/modules/opencode/plugins/omniroute/model-limits.json`

Read `agent-sources.md` (which upstream owns which chain, and what the
undocumented agents are for) and `translation-tables.md` (namespace, order,
aliases, keep-newer gates) before deriving anything.

`verify.py` in this directory runs every static check below. Run it before and
after editing: `python3 .opencode/skills/update-oc-models/verify.py . --live`.

## Rules that are not negotiable

**Follow the doc even when it looks wrong.** A keep-newer gate pinning a dated
id (`claude-haiku-4-5-20251001`) over a polished `-5-5` successor is a
deliberate pin, not an oversight — the 2026-10 precedent documented in
`translation-tables.md`. Keep the documented pick.

**GSD overrides name-similarity guesses.** `gsd-plan-checker` maps to
sonnet-family members, not momus-grade models. Read the catalog, never infer
from the agent name.

**Report, never silently substitute.** Any model with no route, and any alias
that resolves to a different product (`glm-4.6v` → `glm-5.3-flash`), goes in the
diff shown to the user.

## Catalog source

Token-free and authoritative:

```bash
sqlite3 ~/.local/share/omniroute/data/storage.sqlite \
  "select namespace, key, value from key_value
   where namespace in ('syncedAvailableModels','customModels');"
```

Keys are `<provider>:<connectionId>` in `syncedAvailableModels` but the **bare
connection id** in `customModels` — merge both into one prefix or `gh` loses
most of its models. Entries carry `id`, `name`, `source`, `outputTokenLimit`,
and **no modality field**.

`GET /v1/models` needs the Yubikey-backed token. It is a human-run step, not an
agent one; the DB replaces it. Never attempt to read a secret path — the
user's permission rules deny it.

Query the DB in place. It is ~1GB; copying it to scratch buys nothing.

## Procedure

1. Resolve the two upstream store paths from the flake (commands in
   `agent-sources.md`). Pin the revisions via `flake.lock`, never by hand.
2. Dump the catalog, merging `syncedAvailableModels` and `customModels`.
3. Take each chain's owner upstream from the table in `agent-sources.md`. A
   chain usually has several consumers; the owner is the doc you derive
   members from.
4. Derive the members via the order and aliases in `translation-tables.md`.
   Write the derivation as `derive.py` **in this skill directory** and commit
   it, with a case per alias and per keep-newer rule. The 2026-10 run threw its
   script away in `/tmp` and lost eight fixed bugs — merging `customModels`
   into the same prefix, upgrading a date-stamped id, excluding substitute
   variants, counting no-route per model rather than per entry, owner
   precedence, and the litellm fallback slot.
5. Check every resolved member against the live catalog. `provision-combos.sh`
   only warns about an unknown id, and the chain position then 404s at request
   time. Fail the run rather than write that.
6. Show the user a per-chain diff — members added and removed, no-route
   models, and which upstream each chain came from. **Get approval before
   editing.**
7. Write the two files. Every new member needs a `model-limits.json` entry
   (`{"context": N, "output": N}`) or `providers/omniroute.nix:26` throws.
8. `alejandra` any changed `.nix`, then build-gate (below).

## Verify

The build is the gate:

```bash
nix run home-manager/master -- build --flake .#vesecto > /tmp/hm-build.log 2>&1; echo "EXIT=$?"
```

Then run the static checks — one `agent-sources.md` row per chain,
`model-limits.json` covering every member, `ctu/vic/GLM-5.3-Flash` last,
`litellm/*` second-to-last, no duplicate members, a consumer per chain, and no
stale combo in the DB (--live only):

```bash
python3 .opencode/skills/update-oc-models/verify.py . --live
```

The built config is **not** under `result/home-files`. `chains.json` is an
argument on the `ExecStart` line of the provision unit, so read it from there:

```bash
H=$(readlink -f result); U=$H/home-files/.config/systemd/user
grep ExecStart $U/omniroute-provision.service
```

Test file absence with an exit code, never `find … && echo`: `find` exits 0 on
no match, so that idiom reports the opposite of the truth.

Dropping a chain leaves its combo behind: `provision-combos.sh` only deletes
combos it is about to POST, and `combos` has no marker column. `verify.py
--live` reports the strays; remove them in the dashboard. Do not auto-delete
every unlisted `*-chain` — hand-made combos share the suffix.

## Scope

Never `switch` and never commit — the user activates, and commits are
GPG-signed via Yubikey. `nixos-run`'s update action owns pin bumps.
