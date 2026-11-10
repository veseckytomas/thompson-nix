<!--
  ________
 /_  __/ /_  ____  ____ ___  ____  _________  ____
  / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
 / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
/_/ /_/ /_/\____/_/ /_/ /_/ /_/ .___/____/\____/_/ /_/
                             /_/
Tomáš Vesecký
Email: tomas@vesecky.net
GitHub: veseckytomas
GitLab: vesecky.tomas
-->

# Plan: read-only diagnosis — OmniRoute dashboard test-all reports every e-INFRA/LiteLLM model failing (3.8.51)

Mode: **investigation only.** No edits, DB writes, restarts, breaker resets, API-key
reads, network probes to providers, or fixes unless a future turn asks for them.

## 0. Evidence already on file (verified read-only while planning)

| Fact | Source (exact) |
|---|---|
| Connection: generated ID with prefix `litellm`, base URL `https://llm.ai.e-infra.cz/v1`, `max_concurrent=4`, `rate_limit_overrides_json={"maxWaitMs":1}`, `test_status='active'` | `provider_connections` row `431865cf-e0fa-400e-a38c-b531b9c0cbdb`, provider `openai-compatible-chat-4acfd047-f855-4de4-921e-e908657601f0` (read-only SQLite) |
| Caps provenance: cap 4 + maxWaitMs 1 set by repo script | `home-manager/vesecto/modules/opencode/plugins/omniroute/connection-caps.sh:13-14,35-48` |
| Repeated 503 `Request exceeded queue budget maxWaitMs=1ms …` for all connector model names (kimi-k3, deepseek-v4.1-flash, …), durations 4–161 ms | `call_logs` WHERE `connection_id='431865cf…'`, 2026-11-10 13:xx–14:3x |
| `connection-test` request_type rows return **200** at 14:32:41 and 14:44:16 (same window as the 503s) | same table |
| Domain breaker `litellm` OPEN: `failure_count=161`, `openCycleCount=149`, threshold 12, resetTimeout 60000 | `domain_circuit_breakers` WHERE name='litellm' |
| 2134× `"Skipping litellm/<model> — circuit breaker OPEN for litellm"` in app.log | `~/.local/share/omniroute/data/logs/application/app.log` |
| 503 text emitted at | `open-sse/services/rateLimitManager.ts:779` (`Request exceeded queue budget maxWaitMs=…`), pre-check at L709–714 |
| Shared per-provider/connection Bottleneck limiter, key `${provider}:${connectionId}` (generic branch, non-codex/gemini/github) | `rateLimitManager.ts:582-597 getLimiterKey/getLimiter` |
| Queue budget resolves per-connection from `provider_specific_data`/overrides | `rateLimitManager.ts:696-708 resolveRequestQueueMaxWaitMs`, comment L702 (`maxWaitMs=0` semantics), L747-775 execution backstop escalation to upstream 60 s → 16 m |
| test-all runs models through the **chat-completions pipeline** with `runAsProbe`, `withRateLimit` (so the queue applies to tests too) | `src/lib/api/modelTestRunner.ts:1-34` imports (`POST as postChatCompletion`, `withRateLimit`, `runAsProbe`); `DEFAULT_MODEL_TEST_TIMEOUT_MS=30s` |
| Dashboard "Test all" implementation: UI collects `{providerId, connectionId, modelId}` items and fires `POST /api/models/test-all` **in batches of 3** (`chunkItems(items, 3)`) with `Promise.all` per batch, sequential batches | compiled UI chunk `dist/.build/next/server/chunks/ssr/src_1z5n6cp._.js` (`"chunkItems",0,function(a,b=3)…`; fetch body `{providerId, connectionId, modelIds:[e]}`) |
| Route is Next.js app route `[project]/src/app/api/models/test-all/route.ts` | `dist/.build/next/app-path-routes-manifest.json:357`, `server/chunks/_1rtfbrz._.js` (`resolvedPagePath`) |
| omni service active on generated 20128 port; node pid 718327 | `journalctl --user -u omniroute.service` (secrets untouched) |
| Breaker/503s are NOT logged on journald; they live in file log | `journalctl` grep count 0 vs app.log matches |

## 1. Ranked hypotheses

- **H0 (primary, most likely): queue saturation of the shared limiter.**
  Same connection has `max_concurrent=4` and `maxWaitMs=1`. Test-all traffic and normal
  opencode/agent/combo traffic share ONE Bottleneck pool per `${provider}:${connectionId}`.
  When ≥1 slot is busy (retained by any background consumer — combo retries, sidecar
  scheduling, degradation probes), a test request must wait; waits >1 ms are rejected
  instantly as 503 `Request exceeded queue budget maxWaitMs=1ms`. Because the user's
  machine continuously runs combos that mention litellm, **the chance of catching all
  4 slots free is low; most/all models fail immediately regardless of actual upstream
  health.** Auth/base URL/model mismatch would break `connection-test` (200 today), so
  H1 is ruled out *for the batch failure shape*.
- **H1 (ruled out by current evidence, keep as check): auth/base URL/model mismatch.**
  Would persist even with empty pool and would likely fail connection-test too. Current
  `connection-test 200` in the same minute as 503-failing models contradicts it.
- **H2 (secondary, consequence, not root): domain breaker OPEN.**
  OPEN is *downstream* of the 503s: breaker registered them as provider failures
  (161 failures), then flipped OPEN (resetTimeout 60 s, halfOpenRequests 1). While OPEN,
  combos skip litellm (2134 skips) — masking, not causing. A breaker rejection never
  produces the literal `Request exceeded queue budget` text (it produces "circuit breaker
  OPEN" skip messages), so it is distinguishable by error string alone.
- **H3 (possible contributor): per-minute/time-window correlation with background
  autoscheduled traffic.** Test-all batch of 3 in-flight + background kimi-k3 poll from
  window 13:xx-14:3x (observed ~1 per 1–4 min) → slots busy → first test call of each
  batch fails. Even 1 busy slot + 1 ms budget fails on every non-zero wait.

## 2. Minimal ordered evidence-gathering steps (all READ-ONLY)

Every step uses one of: sqlite3 ro connection, `grep`/`Read` of app logs, `Read`/`Grep`
on installed package source (`~/.local/share/omniroute/omniroute@3.8.51`, read-only),
repo source, or compiled UI chunk. No writes anywhere; DB connection URI set
`?mode=ro` + `PRAGMA query_only=ON`. Redact any secret-like column before printing.

### Evidence E1 — timeline correlation between UI test-all and call_logs
Goal: bind the user's exact reproduction timestamps to rows in `call_logs`.

Prep: user states (or dashboard state must be read later) times when "Test all" was
clicked. Baseline query (read-only):

```bash
sqlite3 -header -column 'file:$HOME/.local/share/omniroute/data/storage.sqlite?mode=ro' \
 "PRAGMA query_only=ON;
 SELECT timestamp, connection_id, model, requested_model, provider, status, duration, error_summary
 FROM call_logs
 WHERE connection_id='431865cf-e0fa-400e-a38c-b531b9c0cbdb'
 ORDER BY timestamp;"
```

Pass criterion for round-robin shape (concurrency 4): 503 rows cluster in bursts of ≤4
(complete batches), durations < ~200 ms, and **consistent across all models** in same
time span. Binary decision:
- burst size and per-second ordering match UI batch semantics (4 in parallel, etc.) →
  supports H0 as *primary immediate cause* (queue contention, batch-driven).
- no matching burst at user's reported time, yet connections 503 later → strengthens
  H3 (background traffic is the queue consumer — H0 still primary but not caused
  by dashboard alone).
- if during a chosen window all four slots are provably free (`RATE-LIMIT` log lines
  show no other provider consuming that second), but test-all still 503 → H0-main
  falsified; investigate "test-all uses a separate pool (no queue wait)" (H4).

### Evidence E2 — count/order of test batch from UI + logs
Goal: confirm dashboard "Test all" truly parallelizes by 4 or by 3, from both sides.

- UI side: read-only check of compiled chunk `src_1z5n6cp._.js` already proves batching
  (`chunkItems(b, 3)` — three parallel fetches per batch, sequential batches). Read
  source route `src/app/api/models/test-all/route.ts`-equivalent compiled at
  `dist/.build/next/server/app/api/models/test-all/route.js` + its chunk
  `src_lib_11r-h4-._.js` to find handler-body: does one POST test 1 model or all N?
  `modelIds:[e]` array of 1 suggests **1 model per POST**, N POSTs total
  batched 3-at-a-time by the UI loop.
- Log side: from `call_logs` of one test batch, expect N rows with `request_type`
  matching "connection-test"/probe and near-identical timestamps within each UI batch
  (3 rows, `Promise.all`-parallel).
- Count of *ids* (model names) in `provider_connections.rate_limit_overrides_json`
  scope and prior tests: route may test all provider's models; verify from results count
  in UI batch rows.

### Evidence E3 — implementation inspection: does the test request share the queue?
Source path (compiled, read-only): find in installed package:

```
~/.local/share/omniroute/omniroute@3.8.51/node_modules/omniroute/src/lib/api/modelTestRunner.ts
~/.local/share/omniroute/omniroute@3.8.51/node_modules/omniroute/open-sse/services/rateLimitManager.ts
```

`modelTestRunner.ts` imports `withRateLimit` (used by every model test) — proving the
test path passes through the same per-connection Bottleneck gate, subject to
`resolveRequestQueueMaxWaitMs` (reads `maxWaitMs` override) — 1 ms budget. **Together
with max_concurrent=4 the test is guaranteed to lose the queue lottery under any
background load.**

Companion check: `grep -RIn "resolveRequestQueueMaxWaitMs"` and read
`rate_limit_overrides_json` usage to prove it applies per connection.
If it had different behavior for `runAsProbe` (e.g., bypass), search that path too.

### Evidence E4 — breaker sequencing: consequence, not primary cause
Read-only:

```bash
sqlite3 'file:$HOME/.local/share/omniroute/data/storage.sqlite?mode=ro' \
 "SELECT state, failure_count, last_failure_time, options FROM domain_circuit_breakers WHERE name='litellm';"
grep -c 'circuit breaker OPEN for litellm' ~/.local/share/omniroute/data/logs/application/app.log
sqlite3 … "SELECT timestamp, model, error_summary FROM call_logs WHERE connection_id='431865cf…' AND error_summary LIKE '%queue budget%' ORDER BY timestamp;"
```

Binary checks:
- last_failure_time长得早于 any correlation batch (from E1) → breaker walked OPEN on
  background 503s, independent of test-all (H0 still candidate root for the *503s*,
  breaker secondary). E.g., 161 failures to reach OPEN at threshold 12 with
  `openCycleCount=149` implies ~149 prior open/reset cycles of queue-related failures.
- If breaker OPEN timestamps coincide exactly with test-all batch timestamps → dashboard
  contributed 3-4 failures per batch. Still secondary: without continuing 503s (E5)
  breaker would recover after 60 s resetTimeout via half-open.
- Error strings differ: PRIMARY cause = `Request exceeded queue budget maxWaitMs=…`,
  BREAKER consequence = `"Skipping litellm/<model> — circuit breaker OPEN"` in combo
  path. If a *future* test-all round shows breaker-themed errors instead of queue-budget
  503, the breaker is currently intercepting the dashboard tests — then would need
  separate test (count all models via one-off read of `provider_connections` models list
  vs call-logs requested_model column) — pending further precise mapping of where
  breaker is checked inside test path (route source, E3 extension).

### Evidence E5 — background traffic outside test-all (proves saturation independent of dashboard)
Read-only:

```bash
# All 503s grouped per minute
sqlite3 'file:$HOME/…/storage.sqlite?mode=ro' \
 "SELECT strftime('%Y-%m-%dT%H:%M', timestamp) AS m, count(*), min(timestamp), max(timestamp)
 FROM call_logs WHERE connection_id='431865cf…' AND status=503 GROUP BY m ORDER BY m;"
```

- If 503s continue in minutes with no dashboard interaction → background alone owns the
  queue at those moments; dashboard test-all is *coincidental collateral* (affirms H0,
  refutes "dashboard causes breaker").
- If 503s are exclusively in test-all bursts → dashboard rounds themselves re-OPEN the
  breaker each cycle (H0-dashboard-contribution variant).

### Evidence E6 — auth/baseURL/model mismatch elimination
Read-only, no provider probes needed; purely local comparisons:

```bash
sqlite3 … "SELECT timestamp, model, request_type, status FROM call_logs
 WHERE connection_id='431865cf…' AND request_type LIKE '%connection%' AND status=200
 ORDER BY timestamp DESC LIMIT 5;"
```

- 200 at 14:32 and 14:44 vs 503 in-between at 14:39: **auth and base URL are fine**;
  model mismatch would give different error text (e.g., 404/"not found", observed text
  is exclusively queue-budget). Consider eliminated.
- If (not seen) connection-test itself also fails, only then escalate to checking
  `provider_specific_data` shape (redacted) — never key values.

## 3. Browser fallback (only if E1 timing can't be anchored)

Allowed ONLY when user's timestamp is unavailable and DB lacks probe batch rows:
use existing `omniroute` dashboard session via a pinned Playwright headless session,
capture current `modelIds` count the UI would send, at `http://localhost:20128/`, before
that user manually clicks. No clicking, no state change. This is last resort; never
fetch `/api/models/test-all` POST. Otherwise skip browser entirely.

## 4. TDD-oriented planning (verification-first diagnostics)

Each hypothesis converts to a check as a falsifiable assertion:

- H0 assertion: "a litellm-connection POST arrives at slot-conscious limiter with ≥1 slot
  busy → 503 within ≤1 ms (observed 4-161 ms incl. logging overhead)". Negative test =
  RATE-LIMIT logs showing 0 % slot occupancy at that instant.
- H2 assertion: "breaker OPEN → any litellm chat/completions returns skip-log, not
  503-queue-budget". Counter-example today already exists (503 rows persist), so
  breaker is NOT currently the thing generating the 503s.
- Fix-proposal rehearsal (do-not-apply): if primary cause confirmed, next phase would be
  a red test proving `maxWaitMs=1` kills the test-under-load; green test would demo
  larger queue budget or concurrency rise preserves combo failover semantics. Kept out
  of this diagnosis-only plan.

## 5. Atomic commit strategy (documentation only)

- Only the plan document itself is committed (this file: `.opencode/plans/…md`).
- Message: `docs(omniroute): read-only test-all diagnosis plan (read-only verification only)`.

## 6. Safety guardrails recap

- sqlite3 opened `mode=ro`; never copies DB; never `.backup`, never UPDATE/DELETE.
- No provider/API probes HTTP or network to `llm.ai.e-infra.cz`.
- No secrets redaction risk: never SELECT credential columns; log reads are grep of
  message text only. Any TSX tree path enumeration (`find`) avoided in narrow dirs.
- No service restarts, no systemctl stop/start, no breaker clearing (`DELETE … breakers`
  is OFF-limits), and no `probeCanDisable` toggling.
- If any read command would block a concurrent writer (shouldn't — WAL enables readers),
  abort that read instead of retrying with writable mode.

## 7. Summary expected outcome table

| Evidence | Reading supports | Reading refutes |
|---|---|---|
| E1/N-burst length | H0 (queue contention) | H1 |
| E3 source trace withRateLimit+override | H0 mechanism confirmed | bypass theory |
| E4 breaker count over time rises independent of dashboard usage | breaker = consequence | breaker = root |
| E5 503s continue outside clicks | background alone saturates | dashboard-only theory |
| E6 connection-test 200s | auth/URL OK | H1 |
