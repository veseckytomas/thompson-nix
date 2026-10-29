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

# Translation tables

omo names a model by its upstream provider namespace. OmniRoute names it by
connection prefix. Everything below converts between the two.

## Provider namespace → OmniRoute prefix

| omo provider | prefix | notes |
|---|---|---|
| anthropic, anthropic-api | cc | Claude direct |
| chatgpt-subscription, openai | cx | Codex direct |
| github-copilot | gh | |
| google | antigravity | also carries some older Claude models and gpt-oss |
| opencode-go, kimi-for-coding, moonshotai, moonshotai-cn | litellm | e-infra |
| zai-coding-plan, deepseek, bailian-coding-plan | litellm | |
| aihubmix, ollama-cloud, firmware | litellm | |
| opencode, minimax, minimax-cn, xai | *(none)* | no route — report only |

Connection ids behind the prefixes: `litellm` = openai-compatible
`4acfd047…` (e-infra, `https://llm.ai.e-infra.cz/v1`), `ctu` = `1b0f4418…`
(`vic/*`).

## Member order

Fixed, per chain:

1. direct — `cc/` or `cx/`
2. `gh/`
3. `antigravity/`
4. `litellm/<best fit for the chain>` — always second-to-last
5. `ctu/vic/GLM-5.3-Flash` — always last

If omo lists no litellm entry for a chain, synthesize one to match the chain's
weight: `glm-5.3` for heavyweight chains, `glm-5.3-flash` for lightweight ones.

## Model aliases

omo id on the left, resolved target on the right.

| omo model | resolves to |
|---|---|
| kimi-for-coding-highspeed | litellm/kimi-k3 |
| deepseek-flash | litellm/deepseek-v4.1-flash |
| deepseek-v4-pro | litellm/deepseek — always the newest deepseek |
| glm-5.2 | glm-5.3 |
| glm-4.6v | glm-5.3-flash — **silent substitution, 4.6v has no catalog entry** |
| qwen3.6-flash | qwen3.8-flash-next |
| qwen3.7-plus | qwen3.8-27b |
| gpt-6-luna-fast | cx/gpt-6-luna |
| gpt-5.6-sol-fast | cx/gpt-5.6-sol |
| gpt-6.1-sol-fast | cx/gpt-6.1-sol |
| gpt-5-nano | cx/gpt-5.6-luna |

Qwen is an acceptable substitute for deepseek. Gemini Flash is an acceptable
substitute for gemini-3.1-pro.

## Keep newer

When a newer release of the same product line exists, prefer it — across family
versions, not just dated variants. **An upgrade only counts if the pinned
gateway can shape it:** check `src/shared/constants/modelSpecs.ts` in the
installed `omniroute@<pin>` first. Routing reads the live catalog, but request
shaping (max_tokens cap, tool_choice, thinking support) reads that static
table — a model that routes but is absent from it mis-resolves by prefix and
400s. On the 3.8.51 pin the claude `-5-5` line is absent, so the upgrades
below are gated OFF until the pin catches up:

- `claude-haiku-4-5-20251001` → ~~`claude-haiku-5-5`~~ (gated: not in 3.8.51 spec table)
- `claude-sonnet-5` → ~~`claude-sonnet-5-5`~~ (gated: not in 3.8.51 spec table)
- `claude-opus-4-6` → ~~`claude-opus-5-5`~~ (gated: not in 3.8.51 spec table)

Re-enable by deleting the "(gated…)" notes once the pin's spec table carries
the `-5-5` ids (`grep -c '"claude-opus-5-5"' …/modelSpecs.ts` > 0).

Strip a trailing `-20\d{6}` date stamp before comparing versions, or the dated
id sorts below its successor and the upgrade silently fails.

Never auto-select these variants as a substitute:
`-tiered`, `-lite`, `-disabled`, `-utility`, `-preview`, `-reserve`, and the
`exec-agent` / `copilot-search` / `trajectory` families.

## Bare ids

Write the bare model id in `chains.json`, never a suffixed variant. Two entries
differing only by a suffix (`cx/gpt-5.6-sol-medium`, `cx/gpt-5.6-sol-ultra`)
are the same model in one fallback slot, not two — the second is a dead retry
against the same target.
