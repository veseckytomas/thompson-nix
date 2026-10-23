# Where each chain's documentation lives

Three upstreams, three different shapes. A chain is "documented" only if it
appears in one of the first two. Never invent a tier for the third group.

Resolve upstream paths from the flake, never from a hardcoded store path:

```bash
nix eval --raw --impure --expr '(builtins.getFlake (toString ./.)).inputs.oh-my-openagent.outPath'
nix eval --raw --impure --expr '(builtins.getFlake (toString ./.)).inputs.get-shit-done-redux.outPath'
```

## 1. omo — 19 chains

`packages/model-core/src/agent-model-requirements.ts` and
`category-model-requirements.ts`.

Each agent/category has a `fallbackChain` array, ordered **best first**. Entry 1
is the intended model; its `variant` is the intended effort.

- Chain tier = `variant` of entry 1. `off` maps to `none`.
- Entry 1 with no `variant` means no documented effort — keep the current tier.
- Agent/category → chain name comes from `~/.omo/omo.jsonc` (`omniroute/<chain>`).
  Category `deep-low` drives `deep-chain`.

Covered: sisyphus, sisyphus-junior, hephaestus, oracle, metis, momus,
prometheus, atlas, librarian, explore, multimodal-looker, ultrabrain, artistry,
quick, visual-engineering, unspecified-low, unspecified-high, deep-high,
deep-low.

Rejected aggregators: highest / modal / median across the whole chain. All three
push quick, explore, librarian and writing to max. Entry 1 is the rule.

## 2. GSD — 7 chains

`gsd-core/bin/shared/model-catalog.json`, key `agents` (35 agents).

GSD does **not** store an effort per agent. It stores a tier per profile, and
efforts live in `runtimeTierDefaults.codex`. Read the tier under the active
profile (`model_profile`, default `balanced`), then map:

| tier | codex model | reasoning_effort |
|---|---|---|
| opus | gpt-5.6-sol | xhigh |
| sonnet | gpt-5.6-terra | medium |
| haiku | gpt-5.6-luna | medium |

`adaptiveTierMap` translates `routingTier` (heavy/standard/light) to the same
opus/sonnet/haiku names — use it only under the `adaptive` profile.

One representative agent per chain, chosen because several GSD agents share a
chain:

| chain | representative agent | balanced | effort |
|---|---|---|---|
| gsd-planner-chain | gsd-planner | opus | xhigh |
| gsd-plan-checker-chain | gsd-plan-checker | sonnet | medium |
| gsd-reasoning-chain | gsd-assumptions-analyzer | sonnet | medium |
| gsd-audit-chain | gsd-code-reviewer | sonnet | medium |
| gsd-research-chain | gsd-advisor-researcher | sonnet | medium |
| gsd-background-chain | gsd-codebase-mapper | haiku | medium |
| deep-chain | gsd-debugger | sonnet | medium |

GSD is authoritative for these seven. It overrides any guess based on a
similarly-named omo agent: gsd-plan-checker is sonnet, not momus-grade.

## 3. No upstream documentation — 5 chains

Not in omo and not in GSD. Keep their current tier and members; there is nothing
to be faithful to. Each entry records what the agent is for, so a later run does
not have to rediscover it.

### general-chain
opencode's own built-in `general` agent — multi-step research and parallel work
units. Not an omo agent, so omo never documents it. **Decision: follow
sisyphus-chain**, since it is the same kind of generalist driver.

### didaskalos-chain
thompson-obsidian subagent (`.opencode/agents/didaskalos.md`). Turns staged
lecture recordings, slides and transcripts into citation-grade vault notes, and
repairs existing lecture notes against their staged sources. Long multimodal
input, citation accuracy matters. Current tier: high.

### eurybates-chain
thompson-obsidian agent (`mode: all`) — executive assistant for the vault:
inbox briefings, reply drafts, LinkedIn drafts, thread notes, TODOs, calendar.
Reads and drafts freely, never decides to send. Its own agent file calls the
chain "deliberately a strong chain" and warns against compensating elsewhere —
do not weaken it. Current tier: medium.

### mageiros-chain
thompson-obsidian subagent. Staged recipe extract to finished Czech recipe note;
also fixes existing recipe notes. Narrow, templated, cheap. Current tier: medium.

### reword-chain
**Orphaned.** Defined in `chains.json` and `reasoning-rules.sh`, but no agent
anywhere references it (checked both obsidian worktrees and this repo). Keep it
untouched, or raise removal with the user — never silently retier or delete it.

## Vision

The catalog records no modality at all (`id`, `name`, `source`,
`outputTokenLimit`). Never infer vision from a model id.

OmniRoute's Vision Bridge (`src/lib/guardrails/visionBridge.ts`) is combo-aware
and enabled by default (`VISION_BRIDGE_DEFAULTS.enabled: true`; no
`visionBridge*` / `modalityBridge*` override rows exist). For a mixed chain
`getComboVisionBridgeDecision` returns `process`, so text-only members receive a
text description instead of failing. Mixed-capability tails are supported by
design — not a reason to reject a chain.

`FORCED_VISION_BRIDGE_MODELS` exists because some providers *overstate* vision
support, which is why upstream capability metadata is not trusted here.
