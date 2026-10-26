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

## All-targets-skipped 429 and `Retry-After` poisoning

**`Service temporarily unavailable: all targets were skipped by pre-dispatch filters` with a multi-hour/day `Retry-After` means some connection holds a far-future persisted `provider_connections.rate_limited_until` and the gateway quotes it verbatim.** The render path (`computeEarliestSkippedRateLimitedUntil` in `open-sse/services/combo/comboAttemptLoop.ts`) takes the earliest future persisted cooldown among skipped members — in-memory cooldowns (gh 5h, litellm `max_parallel_requests`) never contribute — so one weekly-limited account (claude's plan reset at 23:00 UTC) parks opencode for ~1 day while later members recover in minutes, because opencode honors the header literally. Live-state facts sit in the sqlite: `rate_limited_until`, `test_status`, `is_active` (dashboard disables stamp `operatorDisabledAt`, audited in `audit_log`).

**The seeded `coolingMaxPeriodCapMs` resilience knob is a no-op in 3.8.51 (zero readers in the package), so `plugins/omniroute/patch-retry-hint.py` clamps the advertised hint to 120 s at that function.** It runs from `installOmniroute` on every switch (idempotent, die-loud on upstream anchor drift — re-derive the clamp on version bumps); clamping only shrinks the *advertised wait*, routing is untouched. Chosen over removing the weekly-limited member from the chain, which would both change routing and be stomped by `provision-combos.sh` re-syncs.

## Version pin held below `latest`

**`omniroute` is pinned to 3.8.51 deliberately — 3.8.52 is broken, so do not "update" it to `latest`.** On 3.8.52 every thinking-enabled request to a `cc/` member dies with Anthropic 400 `` `thinking` or `redacted_thinking` blocks in the latest assistant message cannot be modified `` (upstream issue #17324): `prepareClaudeRequest` rewrites each non-latest thinking block to a `redacted_thinking` carrying one hardcoded placeholder signature, and Anthropic rejects the repeat. Our `reasoning-rules.sh` forces effort ≥ `low`, so the bug fires on every medium-tier chain — 528 failures in one day — while effort-`none` chains (explore, librarian) stay clean. 3.8.52 also stops dropping `litellm/kimi-k3` at `medium` chains, producing a second 400 (`thinking_effort` accepts only low/high/max); both faults disappear on 3.8.51.

**The pin is load-bearing, not bookkeeping:** `installOmniroute` (`gateway.nix`) prunes every `omniroute@*` directory that is not the pinned one, so a single `home-manager switch` with the pin back at 3.8.52 reinstalls it, deletes the running 3.8.51 tree, and repoints `ExecStart` — the bug returns in one step. `nixos-run`'s update action does not auto-bump this file (it only runs `verify_npm_pins`, a 404 check), so the regression can only come from a hand edit. The pin *is* interpolated into the unit, so `grep -o 'omniroute@[0-9.]*' result/home-files/.config/systemd/user/omniroute.service` after a build confirms it; check the live service with `systemctl --user show omniroute.service -p ExecStart`.
