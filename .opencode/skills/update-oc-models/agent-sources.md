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

# Which upstream owns each chain

Every chain in `chains.json` appears exactly once in the table below. A chain is
documented by omo, by GSD, or by neither. `verify.py` enforces the
one-row-per-chain rule, so a chain added upstream fails the check until it is
classified here.

Resolve upstream paths from the flake, never from a hardcoded store path:

```bash
nix eval --raw --impure --expr '(builtins.getFlake (toString ./.)).inputs.oh-my-openagent.outPath'
nix eval --raw --impure --expr '(builtins.getFlake (toString ./.)).inputs.get-shit-done-redux.outPath'
```

## Sharing is normal

One chain serves many agents — `gsd-background-chain` has eight consumers, and
`general` rides `sisyphus-chain`. Sharing is not a smell and never a reason to
split a chain.

It does mean **a chain has exactly one owner**: the source named in the table.
Every other consumer is a rider. `deep-chain` is owned by omo's `deep-low`
category, even though GSD's `gsd-debugger` also rides it.

Build the consumer map from `omo.jsonc` rather than by eye — the file is strict
JSON today, so `json.load` after stripping `//` comments is enough:

```bash
python3 -c "import json;d=json.load(open('home-manager/vesecto/modules/opencode/plugins/oh-my-openagent/omo.jsonc'));[print(m[10:],s[0]+':'+n) for s in ('agents','categories') for n,v in d[s].items() for m in v.get('models',[]) if m.startswith('omniroute/')]"
```

## The table

`src` is the owner. `omo:<key>` means
`packages/model-core/src/{agent,category}-model-requirements.ts`;
`gsd:<agent>` means `gsd-core/bin/shared/model-catalog.json`.

| chain | src |
|---|---|
| sisyphus-chain | omo:sisyphus |
| sisyphus-junior-chain | omo:sisyphus-junior |
| hephaestus-chain | omo:hephaestus |
| oracle-chain | omo:oracle |
| metis-chain | omo:metis |
| momus-chain | omo:momus |
| prometheus-chain | omo:prometheus |
| atlas-chain | omo:atlas |
| librarian-chain | omo:librarian |
| explore-chain | omo:explore |
| multimodal-looker-chain | omo:multimodal-looker |
| ultrabrain-chain | omo:ultrabrain |
| artistry-chain | omo:artistry |
| quick-chain | omo:quick |
| visual-engineering-chain | omo:visual-engineering |
| writing-chain | omo:writing |
| unspecified-low-chain | omo:unspecified-low |
| unspecified-high-chain | omo:unspecified-high |
| deep-chain | omo:deep-low |
| deep-high-chain | omo:deep-high |
| gsd-planner-chain | gsd:gsd-planner |
| gsd-plan-checker-chain | gsd:gsd-plan-checker |
| gsd-reasoning-chain | gsd:gsd-assumptions-analyzer |
| gsd-audit-chain | gsd:gsd-code-reviewer |
| gsd-research-chain | gsd:gsd-advisor-researcher |
| gsd-background-chain | gsd:gsd-codebase-mapper |
| didaskalos-chain | none |
| eurybates-chain | none |
| mageiros-chain | none |

## 1. omo

Each agent/category has a `fallbackChain` array, ordered **best first**. Entry 1
is the intended model. Agent/category → chain comes from `omo.jsonc`
(`omniroute/<chain>`).

Parse the whole object, not a regex sweep. A 2026-10 run missed `writing`
entirely because its key opens with `requiresAnyModel` before `fallbackChain`,
and the regex only recognised the common shape. A chain silently absent from the
table is the failure mode this file exists to prevent.

`writing` is the only key carrying `requiresAnyModel: true`: upstream intends the
lane to go **unavailable** rather than fall back to a non-Claude family. The
repo deliberately overrides that with the standard `litellm` + `ctu` tail, so
availability wins over family purity here. Do not "fix" the tail to match
upstream — see `translation-tables.md`.

## 2. GSD

`gsd-core/bin/shared/model-catalog.json`, key `agents` (35 agents).

Several GSD agents share a chain, so the table names one representative each.
GSD is authoritative for the chains it owns and overrides any guess from a
similarly-named omo agent.

## 3. No upstream documentation

Keep the current members; there is nothing to be faithful to. Each entry below
records what the agent is for, so a later run need not rediscover it.

A chain here must still have a consumer. Before trusting one, grep this repo and
both obsidian worktrees for an agent whose `model:` names it. If nothing
references it, propose removing the chain. `verify.py` runs this check every
time, but it only reads `omo.jsonc`, so the three chains below are an exempt set
hardcoded in the script — their consumers live in another repo. A new obsidian
chain has to be added to that set by hand.

### didaskalos-chain
thompson-obsidian subagent (`.opencode/agents/didaskalos.md`). Turns staged
lecture recordings, slides and transcripts into citation-grade vault notes, and
repairs existing lecture notes against their staged sources. Long multimodal
input, citation accuracy matters.

### eurybates-chain
thompson-obsidian agent (`mode: all`) — executive assistant for the vault:
inbox briefings, reply drafts, LinkedIn drafts, thread notes, TODOs, calendar.
Reads and drafts freely, never decides to send. Its own agent file calls the
chain "deliberately a strong chain" and warns against compensating elsewhere —
do not weaken it.

### mageiros-chain
thompson-obsidian subagent. Staged recipe extract to finished Czech recipe note;
also fixes existing recipe notes. Narrow, templated, cheap.

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
