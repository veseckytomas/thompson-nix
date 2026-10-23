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

# OmniRoute and opencode gotchas

## Chain invariants

**OmniRoute chains carry two invariants:** every chain in `chains.json` ends with `ctu/vic/GLM-5.3-Flash` (the unmetered self-hosted last resort, documented in the VPN-only wiki at `https://gitlab.dev1/ppsr-26/ai-coding/lokalni-ai/-/wikis/home` — `strategy` is `priority`, so keep it last), and `contextCeiling` in `providers/omniroute.nix` caps every advertised window at 250k to avoid context rot. `limit.context` is `min(member floor, ceiling)`, so the clamp only lowers — `quick-chain` stays at 128k because `litellm/mini` is genuinely that small. Adding a chain member needs a `model-limits.json` entry too, or the eval throws by design.

## `omo.jsonc` migrations

**`omo.jsonc` is a read-only store symlink, so its `_migrations` list must name every upstream migration id — including the ones that are no-ops for us.** The loader reads user config only from `~/.omo/omo.jsonc` (`detectUserOmoJsonPath`), and a missing marker re-arms the matching migration. For `mode: "replace-target"` plans `legacySourcesExist` is just `existsSync(targetPath)`, so the config's own presence arms them, and the write then hits `assertConfigPathIsSafe` → `Refusing to edit symlinked omo config`, which surfaces as a `[config-migration]` warning at every startup. Four of the five are additionally gated by a `shouldRun` that our already-canonical config fails, but `2026-08-reasoning-unification` has **no `shouldRun` at all** — it fires purely on marker absence even though its transform changes nothing here (we set none of `reasoning`/`variant`/`reasoningEffort`/`thinking`). Judge each id by tracing its gate in the shipped bundle, never by whether the migration sounds relevant; on a bump, diff the plan list and add any new id. A dropped-marker regression is silent in the build and only shows up as every agent falling back to opencode's default model, because the failed load yields `DEFAULT_RAW_CONFIG` (`{agents:{},categories:{}}`).

## `omo.jsonc` `models` key

**`omo.jsonc` uses `models` (upstream folded `model`+`fallback_models` into it; `models[0]` is the primary, anything past it is dead since `[opencode].runtime_fallback.enabled` is `false`) — and entries must be ids opencode exposes (`omniroute/<chain>`), never gateway-internal prefixes like `ctu/` or `gh/`. Last-resort routing goes at the tail of a chain in `chains.json`. Upstream rejects the old `fallback_models` key outright now (unknown key → TUI shows "config invalid - run doctor"), so never re-add it.**

## Per-provider concurrency caps

**OmniRoute per-provider concurrency caps are Nix-provisioned, not dashboard state:** `plugins/omniroute/connection-caps.{nix,sh}` sets `provider_connections.max_concurrent=4` on the e-infra `litellm` connection before every gateway start, so `executeTargetGates` skips a full litellm pool and the priority chain advances to the next member instead of queueing. The cap is identified by `json_extract(provider_specific_data,'$.prefix')='litellm'`, and a manual dashboard edit of this value is stomped the next time `omniroute-connection-caps` runs — normally on the next `omniroute.service` start — because Nix is the source of truth; the gateway itself reads the cap per request, so no gateway restart is needed once the DB is written. The `ctu` connection intentionally stays uncapped (NULL).

## Combo-keyed tables and unit ordering

**A combo-keyed OmniRoute table must order `After=omniroute-provision.service`, never `Before=omniroute.service`:** `provision-combos.sh` DELETEs then re-POSTs every chain, so combo ids regenerate on each activation, and `reasoning_routing_rules` and `model_combo_mappings` both declare `REFERENCES combos(id) ON DELETE CASCADE` — a `Before=` unit writes rows against the old ids and provisioning then silently cascades them away, leaving zero rows, no error and no log line. `plugins/omniroute/reasoning-rules.{nix,sh}` is the one unit ordered this way and resolves each `combo_id` by chain *name* at runtime; its `Before=` siblings (`connection-caps`, `normalize-providers`, `resilience-defaults`) are correct because they write `provider_connections` and `key_value`, which nothing regenerates.

## MCP `status=failed`

**An MCP `status=failed` warning usually means `enabled = false`, not a broken server:** opencode logs a *disabled* local server exactly like a crashed one — `WARN message="server unavailable" key=<name> type=local status=failed` — and it emits that on demand, when an agent first reaches for the server's tools, so the warning surfaces mid-session rather than at startup. `opencode mcp list` is the only thing that separates the two (`disabled` vs `failed`); check it before debugging the binary, and flip the `enabled` flag in `home-manager/vesecto/modules/opencode/default.nix`.

## Provider/500 diagnostics

**opencode provider/500 errors → query OmniRoute `call_logs`, not journald:** the gateway only logs service start/fatal to the journal; per-call failures live in `~/.local/share/omniroute/data/storage.sqlite` (queries + `omniroute logs/health` shorthands in the repo `README.md` Diagnostics section).
