<!--
  ________
 /_  __/ /_  ____  ____ ___  ____  _________  ____
  / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
 / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
/_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
                         /_/
Tomáš Vesecký
Email: tomas@vesecky.net
GitHub: veseckytomas
GitLab: vesecky.tomas
-->

# OmniRoute and opencode gotchas

## `omniroute-resilience-readers: FAIL <leaf>`

**The gate asserts that every seeded resilience leaf is still read at runtime; a FAIL means the literal in `verify-omniroute-resilience-readers.py`'s `CONTRACTS` no longer matches upstream's text, which is not the same as the reader being gone.** Decide which before touching the literal: trace the leaf to its decision in the packed tarball (`npm pack omniroute@<version>`), and retarget only if the read survives — for `comboCooldownWait.budgetMs` that means `budgetLeftMs` still reaching `comboAttemptLoop.ts`. A genuinely dropped reader means the seeded value is dead config and must be reported, never papered over by relaxing the literal. Retargeting also means updating the matching fixture in `verify-omniroute-resilience-readers-test.sh`, whose `@`-free steps are tokenized exactly — a trailing comma is a mismatch. Both run under `checks.x86_64-linux.lint`.

## Chain invariants

**A version downgrade poisons `providerSpecificData` secrets (gh/ 2026-11-02):** ≥3.8.52 encrypts PSD secret fields (`copilotToken` et al. — `PROVIDER_SPECIFIC_SECRET_FIELDS`) at rest **and decrypts on read**; 3.8.51 neither, so rows ciphertext-enveloped under ≥3.8.52 hand the executor a raw `enc:v1:…` string as the Bearer token → GitHub 400 “`IDE token is malformed … invalid token format`”. Real fix = bump the pin back (rebuild). SQL shortcut while stuck on 3.8.51: `json_remove(psd,'$.copilotToken','$.copilotTokenExpiresAt')` + `is_active=1` — the executor refreshes itself with a fresh plaintext sub-token on the next request using the still-valid device-flow `access_token` (decryptable by both versions). Never attempt dashboard re-auth as the cure on 3.8.51: it saves a plaintext PSD row while top-level `refresh_token` stays NULL, so any later ciphertext revert strand-locks the row.

**OmniRoute chains carry two invariants:** every chain in `chains.json` ends with `ctu/vic/GLM-5.3-Flash` (the unmetered self-hosted last resort, documented in the VPN-only wiki at `https://gitlab.dev1/ppsr-26/ai-coding/lokalni-ai/-/wikis/home` — `strategy` is `priority`, so keep it last), and `contextCeiling` in `providers/omniroute.nix` caps every advertised window at 250k to avoid context rot. `limit.context` is `min(member floor, ceiling)`, so the clamp only lowers — `quick-chain` stays at 128k because `litellm/mini` is genuinely that small. Adding a chain member needs a `model-limits.json` entry too, or the eval throws by design.

**Neither invariant binds `pinnedIds`.** A bare member id resolves to no combo (`getComboOrModel` returns null), so a pin is a single-model request with no chain fallback and no last-resort tail — that is the point of pinning, not a violation to repair. The `contextCeiling` clamp still applies. The eval throws on a pinned id missing from `model-limits.json`, and `verify-model-limits.py` (wired into `checks.lint`) gates the spare direction: an entry no chain or pin consumes fails the build, because `limitsOf` never sees it.

## Effort variants on pinned models

**Three independent layers each reorder or drop a variant, so a wrong cycle order is rarely the layer you are editing.** The gateway reads effort from the request body (`effort`, or `reasoning_effort`/`reasoning.effort`/`thinking`, which win when the client sets them); `normalizeReasoningRequest` folds canonical `effort` onto the per-provider field, and the vocabulary is `none|low|medium|high|xhigh|max`. opencode reaches that body because a model's `options`/`variants` values become AI SDK `providerOptions`, which `@ai-sdk/openai-compatible` forwards as top-level body fields — provider-level `options` are constructor settings (`baseURL`, `apiKey`) and never reach it.

Then two layers reorder what you wrote. `reasoning = true` on a model makes opencode prepend `low, medium, high` to its variant cycle, injecting names your config never declared and stranding the rest in file order behind them; `reasoning = false` stops the injection and costs only the picker's reasoning tooltip (reasoning parts are still captured and stored either way). Nix sorts attribute keys alphabetically on output, so declaration order alone is lost even after the injection stops — chain the entries with `lib.hm.dag.entryAfter` (the first entry stays a bare attrset, or its DAG wrapper leaks into the JSON as `{after, before, data}`), which is why `providers/omniroute.nix` takes `{lib}` and `default.nix` passes it.

**Isolate with `XDG_CONFIG_HOME`, never `OPENCODE_CONFIG` alone:** the latter still merges the user's real config, so readings silently inherit `~/.config/opencode` and contradict each other between runs. Read the resolved order back from `opencode serve` → `GET /config/providers` (strip `plugin`/`mcp`/`agent`/`command` from the copied config so the server boots offline), and confirm the body with a local listener rather than the gateway's `call_logs`, whose `reasoning_effort_requested` column stays empty on these requests.

## `omo.jsonc` migrations

**`omo.jsonc` is a read-only store symlink, so its `_migrations` list must name every upstream migration id — including the ones that are no-ops for us.** The loader reads user config only from `~/.omo/omo.jsonc` (`detectUserOmoJsonPath`), and a missing marker re-arms the matching migration. For `mode: "replace-target"` plans `legacySourcesExist` is just `existsSync(targetPath)`, so the config's own presence arms them, and the write then hits `assertConfigPathIsSafe` → `Refusing to edit symlinked omo config`, which surfaces as a `[config-migration]` warning at every startup. Four of the five are additionally gated by a `shouldRun` that our already-canonical config fails, but `2026-08-reasoning-unification` has **no `shouldRun` at all** — it fires purely on marker absence even though its transform changes nothing here (we set none of `reasoning`/`variant`/`reasoningEffort`/`thinking`). Judge each id by tracing its gate in the shipped bundle, never by whether the migration sounds relevant; on a bump, diff the plan list and add any new id. A dropped-marker regression is silent in the build and only shows up as every agent falling back to opencode's default model, because the failed load yields `DEFAULT_RAW_CONFIG` (`{agents:{},categories:{}}`).

## `omo.jsonc` `models` key

**`omo.jsonc` uses `models` (upstream folded `model`+`fallback_models` into it; `models[0]` is the primary, anything past it is dead since `[opencode].runtime_fallback.enabled` is `false`) — and entries must be ids opencode exposes (`omniroute/<chain>`), never gateway-internal prefixes like `ctu/` or `gh/`. Last-resort routing goes at the tail of a chain in `chains.json`. Upstream rejects the old `fallback_models` key outright now (unknown key → TUI shows "config invalid - run doctor"), so never re-add it.**

## Per-provider concurrency caps

**OmniRoute per-provider concurrency caps are Nix-provisioned, not dashboard state:** `plugins/omniroute/connection-caps.{nix,sh}` sets `provider_connections.max_concurrent=4` and `rate_limit_overrides_json.maxWaitMs=1` on the e-infra `litellm` connection before every gateway start. The cap makes `executeTargetGates` skip a full litellm pool; the maxWaitMs override shortens the *other* wait — the account semaphore in `chatCore` (`acquireConcurrencyGates`, key `provider:<connectionId>`, shared by every chain at once) instant-fails (1ms) on a full pool instead of the global 60s `requestQueue.maxWaitMs`, so overflowed members cascade to the next chain member immediately; `0` would instead inherit the global 60s wait because the override resolver only honors values > 0. The cap is identified by `json_extract(provider_specific_data,'$.prefix')='litellm'`, and a manual dashboard edit of either value is stomped the next time `omniroute-connection-caps` runs — normally on the next `omniroute.service` start — because Nix is the source of truth; the override map is loaded at gateway startup only, so a hand-written `rate_limit_overrides_json` needs a gateway restart to load (the deployed script runs pre-start, so the normal flow already has it). The `ctu` connection intentionally stays uncapped (NULL).

## Combo-keyed tables and unit ordering

**A unit that writes a combo-keyed OmniRoute table must order `After=omniroute-provision.service`, never `Before=omniroute.service`:** `provision-combos.sh` DELETEs then re-POSTs every chain, so combo ids regenerate on each activation, and `model_combo_mappings` declares `REFERENCES combos(id) ON DELETE CASCADE` — a `Before=` unit writes rows against the old ids and provisioning then silently cascades them away, leaving zero rows, no error and no log line. Such a unit must also resolve each `combo_id` by chain *name* at runtime rather than from a captured id. No current unit writes a combo-keyed table; the existing `Before=` units (`connection-caps`, `normalize-providers`, `resilience-defaults`, `compression-defaults`) are correct because they write `provider_connections` and `key_value`, which nothing regenerates.

## MCP `status=failed`

**An MCP `status=failed` warning usually means `enabled = false`, not a broken server:** opencode logs a *disabled* local server exactly like a crashed one — `WARN message="server unavailable" key=<name> type=local status=failed` — and it emits that on demand, when an agent first reaches for the server's tools, so the warning surfaces mid-session rather than at startup. `opencode mcp list` is the only thing that separates the two (`disabled` vs `failed`); check it before debugging the binary, and flip the `enabled` flag in `home-manager/vesecto/modules/opencode/default.nix`.

## Provider/500 diagnostics

**opencode provider/500 errors → query OmniRoute `call_logs`, not journald:** the gateway only logs service start/fatal to the journal; per-call failures live in `~/.local/share/omniroute/data/storage.sqlite` (queries + `omniroute logs/health` shorthands in the repo `README.md` Diagnostics section; deeper reads in Forensic SQLite queries below).

## All-targets-skipped 429 and `Retry-After` poisoning

**`Service temporarily unavailable: all targets were skipped by pre-dispatch filters` with a multi-hour/day `Retry-After` means some connection holds a far-future persisted `provider_connections.rate_limited_until` and the gateway quotes it verbatim.** The render path (`computeEarliestSkippedRateLimitedUntil` in `open-sse/services/combo/comboAttemptLoop.ts`) takes the earliest future persisted cooldown among skipped members — in-memory cooldowns (gh 5h, litellm `max_parallel_requests`) never contribute — so one weekly-limited account (claude's plan reset at 23:00 UTC) parks opencode for ~1 day while later members recover in minutes, because opencode honors the header literally. Live-state facts sit in the sqlite: `rate_limited_until`, `test_status`, `is_active` (dashboard disables stamp `operatorDisabledAt`, audited in `audit_log`).

**The seeded `coolingMaxPeriodCapMs` resilience knob is a no-op (zero readers in the package through 3.8.53), so `plugins/omniroute/patch-retry-hint.py` clamps the advertised hint to 120 s at that function.** It runs from `installOmniroute` on every switch (idempotent, die-loud on upstream anchor drift — re-derive the clamp on version bumps); clamping only shrinks the *advertised wait*, routing is untouched. Chosen over removing the weekly-limited member from the chain, which would both change routing and be stomped by `provision-combos.sh` re-syncs.

## Version pin released; Kimi `thinking_effort` fault mitigated locally

**`omniroute` was pinned 3.8.51 through 2026-11-08; the pin is lifted as of 3.8.53.** The 3.8.52 blocker (upstream #17324: thinking-enabled `cc/` requests die with Anthropic 400 `` `thinking` or `redacted_thinking` blocks in the latest assistant message cannot be modified ``, because `prepareClaudeRequest` rewrites each non-latest thinking block to a `redacted_thinking` with one hardcoded placeholder signature Anthropic then rejects) was closed 2026-11-02 and shipped in v3.8.53 (2026-11-06); `update-opencode-npm-plugins.sh` lost its omniroute skip-guard accordingly.

**The Kimi half of that knot is still open on 3.8.53** (verified against the 3.8.53 tarball): the upstream parser misses Kimi's `supports thinking_effort values` wording and truncates `max` when a trailing annotation contains a comma, so `litellm/kimi-k3` members 400 with (`thinking_effort` accepts only low/high/max). It provably fired on 3.8.51 too (journal + call_logs, 2026-10-26/27) because the native-Kimi registry vocabulary does not apply to dynamic `openai-compatible-chat-<uuid>/kimi-k3` connections. Mitigated locally since 2026-11-09: `plugins/omniroute/kimi-effort-vocab.sh` (unit `omniroute-kimi-effort-vocab`, Before=omniroute.service) idempotently seeds `model_capability_overrides` ('litellm','kimi-k3','reasoning_efforts') = `["low","high","max"]` --- kimi's own accepted vocabulary, verbatim from its 400 --- read as the authoritative send vocabulary (modelCapabilities.ts, override first in the effort fallback chain). Exits 75 (EX_TEMPFAIL) until the gateway migrates; no restart needed (fresh bulk snapshot per build).

**The pin is still load-bearing:** `installOmniroute` (`gateway.nix`) prunes every `omniroute@*` directory that is not the pinned one, so a `home-manager switch` with an edited pin reinstalls that version, deletes the running tree and repoints `ExecStart` in one step. The pin *is* interpolated into the unit, so `grep -o 'omniroute@[0-9.]*' result/home-files/.config/systemd/user/omniroute.service` after a build confirms it; check the live service with `systemctl --user show omniroute.service -p ExecStart`.

## Forensic SQLite queries

For failures the provider/500 and all-targets-skipped checks can't explain from logs alone, query the live store read-only. All commands use `mode=ro` and select no bodies or credentials, so never add `request_body`, `response_body`, `access_token`, `refresh_token`, `id_token`, `api_key`, `options`, or `details` columns to them.

Set once per shell:

```bash
DB="file:$HOME/.local/share/omniroute/data/storage.sqlite?mode=ro"
```

1. Recent failed calls, newest first, error text truncated to 80 chars. Proves which provider and upstream error produced each 4xx/5xx.

```bash
sqlite3 -header "$DB" "SELECT timestamp, provider, status, substr(coalesce(error_summary,''),1,80) AS err FROM call_logs WHERE status >= 400 ORDER BY timestamp DESC LIMIT 15;"
```

2. Provider cooldown, active, and test state. The CASE renders both ISO text and numeric epoch-ms values of `rate_limited_until` (live rows are text, older ones may differ); a listed row proves the provider is parked by a rate limit, backoff, or failed test rather than by routing choice.

```bash
sqlite3 -header "$DB" "SELECT provider, is_active, test_status, CASE WHEN rate_limited_until GLOB '[0-9]*' AND rate_limited_until NOT GLOB '*[^0-9]*' THEN datetime(CAST(rate_limited_until AS INTEGER)/1000,'unixepoch') ELSE rate_limited_until END AS cooldown_until, backoff_level, last_error_type FROM provider_connections WHERE is_active=0 OR test_status<>'active' OR rate_limited_until IS NOT NULL OR backoff_level>0;"
```

3. Audit warnings, failures, and operator enable/disable actions. `details` is deliberately omitted (it can carry serialized payloads); each row proves whether a change or failure came from a user action or the system, and when.

```bash
sqlite3 -header "$DB" "SELECT timestamp, action, actor, target, status FROM audit_log WHERE action LIKE '%test%' OR action LIKE '%fail%' OR action LIKE '%skip%' OR action LIKE '%enable%' OR action LIKE '%disable%' OR status<>'success' ORDER BY timestamp DESC LIMIT 20;"
```

4. Circuit breakers and active lockouts. Two commands, because the shapes and epoch columns don't UNION cleanly; an OPEN/HALF_OPEN breaker or an unexpired lockout row proves OmniRoute is refusing traffic to that domain regardless of credential health.

```bash
sqlite3 -header "$DB" "SELECT name, state, failure_count, datetime(last_failure_time/1000,'unixepoch') AS last_failure_utc FROM domain_circuit_breakers;"

sqlite3 -header "$DB" "SELECT identifier, attempts, datetime(CAST(locked_until AS INTEGER)/1000,'unixepoch') AS locked_until_utc FROM domain_lockout_state WHERE locked_until IS NOT NULL AND CAST(locked_until AS INTEGER) > unixepoch('now') * 1000;"
```

Empty rows mean healthy state, not a broken query. Effective on 3.8.51; re-check `.schema <table>` after a version bump before trusting a query.
