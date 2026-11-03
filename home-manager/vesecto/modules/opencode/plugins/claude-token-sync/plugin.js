//   ________
//  /_  __/ /_  ____  ____ ___  ____  _________  ____
//   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
//  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
// /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
//                          /_/
// Tomáš Vesecký
// Email: tomas@vesecky.net
// GitHub: veseckytomas
// GitLab: vesecky.tomas

// claude-token-sync — opencode plugin
//
// Keeps ~/.claude/.credentials.json (the file read by @slkiser/opencode-quota
// and by the Claude CLI) in sync with the fresh Anthropic OAuth token that
// opencode-claude-bridge maintains in OpenCode's auth store
// (~/.local/share/opencode/auth.json -> "anthropic").
//
// Why: the bridge rotates the subscription's OAuth token and writes the new
// value ONLY into OpenCode's store. ~/.claude/.credentials.json is left stale,
// so the quota panel eventually can't authenticate until you re-run
// `claude auth login`. This plugin mirrors the bridge's fresh token back into
// ~/.claude so both keep working off the same account.
//
// Design — gated + lazy + one-directional (opencode -> ~/.claude):
//   * On `session.idle` (and credential-change `auth`) events it runs a
//     microsecond staleness check.
//   * It writes ~/.claude ONLY when that file is missing / expired / about to
//     expire AND OpenCode currently holds a fresher, valid token.
//   * Registered BEFORE @slkiser/opencode-quota in the plugin array, so the
//     refresh lands before the quota probe reads the file (no fail-then-recover
//     cycle).
//   * Never writes opencode's store; never throws out of a hook — a sync
//     problem can never break a session.

import {
  readFileSync,
  writeFileSync,
  renameSync,
  mkdirSync,
  chmodSync,
} from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

// Treat ~/.claude as "about to fail" this long before its expiry, so the
// refresh lands before opencode-quota's next probe reads an expired token.
const STALE_BUFFER_MS = 5 * 60 * 1000;
// Require opencode's token to be valid at least this long before we mirror it,
// so we never copy an already-dead token over ~/.claude.
const FRESH_BUFFER_MS = 60 * 1000;

function claudeCredsPath() {
  return join(homedir(), ".claude", ".credentials.json");
}

function opencodeAuthPath() {
  const xdg = process.env.XDG_DATA_HOME;
  const base = xdg && xdg.trim() ? xdg : join(homedir(), ".local", "share");
  return join(base, "opencode", "auth.json");
}

function readJson(path) {
  try {
    return JSON.parse(readFileSync(path, "utf8"));
  } catch {
    return null;
  }
}

// The Anthropic OAuth token OpenCode/the bridge currently holds.
function readOpencodeAnthropic(path) {
  const auth = readJson(path);
  const a = auth && auth.anthropic;
  if (!a || a.type !== "oauth") return null;
  const { access, refresh, expires } = a;
  if (typeof access !== "string" || !access) return null;
  if (typeof refresh !== "string" || !refresh) return null;
  if (typeof expires !== "number" || !Number.isFinite(expires)) return null;
  return { access, refresh, expires };
}

// Atomic, owner-only write that preserves any existing claudeAiOauth metadata
// (subscriptionType, scopes, rateLimitTier, ...).
function writeClaudeCreds(path, existing, oc) {
  const base = existing && typeof existing === "object" ? existing : {};
  const prevOauth =
    base.claudeAiOauth && typeof base.claudeAiOauth === "object"
      ? base.claudeAiOauth
      : {};
  const next = {
    ...base,
    claudeAiOauth: {
      ...prevOauth,
      accessToken: oc.access,
      refreshToken: oc.refresh,
      expiresAt: oc.expires,
    },
  };
  const dir = join(homedir(), ".claude");
  try {
    mkdirSync(dir, { recursive: true, mode: 0o700 });
  } catch {
    // directory already exists / not our problem
  }
  const tmp = `${path}.tmp-${process.pid}-${Date.now()}`;
  writeFileSync(tmp, JSON.stringify(next, null, 2), { mode: 0o600 });
  try {
    chmodSync(tmp, 0o600);
  } catch {
    // best-effort perms
  }
  renameSync(tmp, path);
  return next;
}

/**
 * Core sync. Returns a short status string describing the decision taken.
 * Cheap (read + integer compare) unless a write is actually warranted.
 * Never throws.
 *
 * @param {object} [opts]
 * @param {string} [opts.claudePath]       override ~/.claude/.credentials.json
 * @param {string} [opts.opencodeAuthPath] override opencode auth.json
 * @param {boolean} [opts.dryRun]          compute decision, do not write
 * @returns {string}
 */
export function syncClaudeCredentials(opts = {}) {
  try {
    const cPath = opts.claudePath || claudeCredsPath();
    const oPath = opts.opencodeAuthPath || opencodeAuthPath();
    const now = Date.now();

    const existing = readJson(cPath);
    const claudeTok =
      existing && existing.claudeAiOauth ? existing.claudeAiOauth : null;
    const claudeExp =
      claudeTok && typeof claudeTok.expiresAt === "number"
        ? claudeTok.expiresAt
        : 0;

    // GATE: ~/.claude still authenticates comfortably -> nothing to do.
    if (existing && claudeExp > now + STALE_BUFFER_MS) {
      return "skip: ~/.claude healthy";
    }

    // ~/.claude is missing / expired / about to expire.
    // Can OpenCode supply a fresher token?
    const oc = readOpencodeAnthropic(oPath);
    if (!oc) return "skip: no opencode anthropic oauth token";
    if (oc.expires <= now + FRESH_BUFFER_MS) {
      return "skip: opencode token also stale";
    }

    // Already holding this exact token -> avoid a pointless write.
    if (claudeTok && claudeTok.accessToken === oc.access) {
      return "skip: already current";
    }

    if (opts.dryRun) {
      return `would-sync: write opencode token (exp ${new Date(
        oc.expires,
      ).toISOString()}) into ${cPath}`;
    }

    writeClaudeCreds(cPath, existing || {}, oc);
    return `synced: mirrored opencode token into ${cPath}`;
  } catch (err) {
    return `error: ${err && err.message ? err.message : String(err)}`;
  }
}

// Events that warrant a (gated) sync check. `session.idle` aligns with when
// opencode-quota refreshes its probe; `auth` fires when a provider credential
// changes (the bridge writes via client.auth.set), letting us mirror right at
// rotation time. Unknown/irrelevant event types are ignored.
const TRIGGER_EVENTS = new Set(["session.idle", "auth"]);

function report(result) {
  // Healthy no-ops stay quiet; only surface real writes and errors.
  if (result.startsWith("synced") || result.startsWith("error")) {
    console.error(`[claude-token-sync] ${result}`);
  }
}

export const ClaudeTokenSyncPlugin = async (_ctx) => {
  // Opportunistic sync at load: covers ~/.claude already being stale when
  // OpenCode starts, before the first idle event fires.
  report(syncClaudeCredentials());

  return {
    event: async ({ event } = {}) => {
      if (!event || !TRIGGER_EVENTS.has(event.type)) return;
      report(syncClaudeCredentials());
    },
  };
};

export default ClaudeTokenSyncPlugin;
