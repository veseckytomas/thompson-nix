---
name: update-oc-models
description: Re-derive the OmniRoute chain members and reasoning-effort tiers from upstream docs (omo, GSD) and the live model catalog. Use when bumping oh-my-openagent or get-shit-done-redux, when a provider adds or drops models, or when chains.json / reasoning-rules.sh / model-limits.json drift from upstream.
---

# update-oc-models

Rewrites three files from upstream documentation plus the live catalog:

- `home-manager/vesecto/modules/opencode/plugins/omniroute/chains.json`
- `home-manager/vesecto/modules/opencode/plugins/omniroute/reasoning-rules.sh`
- `home-manager/vesecto/modules/opencode/plugins/omniroute/model-limits.json`

Read `agent-sources.md` (which upstream documents which chain, and what the
undocumented agents are for) and `translation-tables.md` (namespace, order,
aliases, suffixes) before deriving anything.

## Rules that are not negotiable

**Never invent a tier.** A chain is documented by omo or by GSD, or it keeps its
current tier. Five chains have no upstream at all — see `agent-sources.md`.

**Entry 1 wins.** omo's `fallbackChain` is ordered best-first; the chain tier is
entry 1's `variant`, `off` → `none`. Do not aggregate across the chain.

**Follow the doc even when it looks wrong.** omo documents `unspecified-low`
entry 1 as `claude-sonnet-5-5 medium`, which makes it heavier than `quick`
(`low`). That is the documented answer; keep it.

**GSD overrides name-similarity guesses.** `gsd-plan-checker` is `sonnet`
(medium), not momus-grade. Read the catalog, never infer from the agent name.

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
agent one; the DB replaces it. Never attempt to read a `*.gpg` / `*.env` path —
the user's permission rules deny it.

## Procedure

1. Resolve the two upstream store paths from the flake (commands in
   `agent-sources.md`). Pin the revisions via `flake.lock`, never by hand.
2. Dump the catalog, merging `syncedAvailableModels` and `customModels`.
3. For each of the 31 chains, resolve its owner:
   omo (`~/.omo/omo.jsonc` maps agent/category → `omniroute/<chain>`), then GSD,
   else undocumented. When a GSD agent reuses an omo chain, `<name>-chain`
   belongs to `<name>` — a reuser must not displace the owner.
4. Derive the tier, and the members via the order and aliases in
   `translation-tables.md`.
5. Check the tier drop: `filterComboForReasoningDecision` removes members whose
   `capabilityFor` is unsupported at the target effort. If **every** member
   drops, the gateway returns HTTP 400 "Reasoning routing policy leaves no
   compatible combo target". Fail the run rather than write that.
6. Show the user a per-chain diff — members, tier change, no-route models, drop
   warnings, and which upstream each tier came from. **Get approval before
   editing.**
7. Write the three files. Every new member needs a `model-limits.json` entry
   (`{"context": N, "output": N}`) or `providers/omniroute.nix:26` throws.
8. `alejandra` any changed `.nix`, then build-gate (below).

## Verify

The build is the gate:

```bash
nix run home-manager/master -- build --flake .#vesecto > /tmp/hm-build.log 2>&1; echo "EXIT=$?"
```

Then confirm, before claiming success:

- every chain has exactly one rule, and rule count matches combo count
- every member exists in the catalog and in `model-limits.json`
- the last two members are `litellm/*` then `ctu/vic/GLM-5.3-Flash`
- `omniroute-reasoning-rules.service` still has `After=omniroute-provision.service`

After the user activates, verify the live rows:

```bash
sqlite3 ~/.local/share/omniroute/data/storage.sqlite \
  "select combo_name, target_effort, effort_mode, budget_action from reasoning_routing_rules order by combo_name;"
```

Keep `effort_mode='force'` and `budget_action='remove'`. With `budget_action='set'`
the gateway writes a thinking object that shadows `target_effort`.

Rules are provider-agnostic: `applyReasoningRuleDirective`
(`src/lib/reasoningRouting/policy.ts`) writes `reasoning_effort`,
`reasoning.effort` and `output_config.effort`. Do **not** add a `cc/`-only
fallback rule.

## Scope

Never `switch` and never commit — the user activates, and commits are
GPG-signed via Yubikey. `nixos-run`'s update action owns pin bumps.
