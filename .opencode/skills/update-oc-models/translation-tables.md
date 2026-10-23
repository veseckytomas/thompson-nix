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

If omo lists no litellm entry for a chain, synthesize one from the tier:
`glm-5.3` at medium and above, `glm-5.3-flash` at low/none. Both match
`MAX_TIER_REASONING_MODEL_PATTERN`, so they stay valid at max/ultra.

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
versions, not just dated variants.

- `claude-haiku-4-5-20251001` → `claude-haiku-5-5`
- `claude-sonnet-5` → `claude-sonnet-5-5`
- `claude-opus-4-6` → `claude-opus-5-5`

Strip a trailing `-20\d{6}` date stamp before comparing versions, or the dated
id sorts below its successor and the upgrade silently fails.

Never auto-select these variants as a substitute:
`-tiered`, `-lite`, `-disabled`, `-utility`, `-preview`, `-reserve`, and the
`exec-agent` / `copilot-search` / `trajectory` families.

## Effort suffixes

A suffixed id (`cc/claude-opus-5-5-max`) declares a model's effort vocabulary.
Parser: `open-sse/config/providerModels.ts` → `CLAUDE_EFFORT_SUFFIXES`,
`splitClaudeEffortSuffix`.

Under `effort_mode='force'` a rule beats the suffix — `clearDiscreteReasoning`
wipes it — so write the bare id and let the rule carry the effort. Codex path:
`open-sse/executors/codex/reasoningPolicy.ts` uses
`forcedEffort || split.effort || …`.

Declared vocabularies worth remembering: `gh/claude-opus-5.5` and
`cc/claude-haiku-5-5` have **no** `max`; `cc/claude-opus-5`, `cc/claude-opus-5-5`
and `cx/gpt-6-sol` go up to `max`.

Valid `target_effort` (migration 126 CHECK):
`none low medium high xhigh max ultra`. `minimal` is rejected; `ultra` is valid.
