//   ________
//  /_  __/ /_  ____  ____ ___  ____  _________  ____
//   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
//  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
// /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
//                          /_/
// Tomáš Vesecký
// Email: vesecky@proton.me
// GitHub: veseckytomas
// GitLab: vesecky.tomas

// Anthropic 400s past 4 cache_control breakpoints; opencode+OMO can emit 5.
// Markers are lowered onto the /v1/messages body after all plugin hooks run, so
// globalThis.fetch (which the OAuth bridge and API-key mode both call) is the
// only place to trim them.
const MAX_CACHE_CONTROL = 4;

function isAnthropicMessages(url) {
  try {
    return new URL(url).pathname.endsWith("/v1/messages");
  } catch {
    return false;
  }
}

// Anthropic counts cache_control across tools, then system, then messages —
// collect holders in that prefix order so trimming keeps the right ones.
function collectHolders(body) {
  const holders = [];
  const scan = (arr) => {
    if (!Array.isArray(arr)) return;
    for (const block of arr) {
      if (block && typeof block === "object" && block.cache_control) {
        holders.push(block);
      }
    }
  };
  scan(body.tools);
  scan(body.system);
  if (Array.isArray(body.messages)) {
    for (const message of body.messages) {
      if (message && Array.isArray(message.content)) scan(message.content);
    }
  }
  return holders;
}

// Keep the LAST breakpoints: each retained one caches the whole prefix before
// it (tools + system included), so dropping the earliest loses the least.
function capCacheControl(body) {
  const holders = collectHolders(body);
  const excess = holders.length - MAX_CACHE_CONTROL;
  if (excess <= 0) return false;
  for (let i = 0; i < excess; i++) delete holders[i].cache_control;
  return true;
}

// Body length changes after trimming, so drop any caller-set content-length.
function withoutContentLength(headers) {
  if (!headers) return headers;
  if (typeof Headers !== "undefined" && headers instanceof Headers) {
    const clone = new Headers(headers);
    clone.delete("content-length");
    return clone;
  }
  const clone = { ...headers };
  for (const key of Object.keys(clone)) {
    if (key.toLowerCase() === "content-length") delete clone[key];
  }
  return clone;
}

export default {
  id: "cache-control-cap",
  setup: async (ctx) => {
  const original = globalThis.fetch;
  // Guard against a double-wrap if opencode loads the plugin more than once.
  if (!original || original.__cacheControlCapWrapped) return;

  const wrapped = async (input, init) => {
    try {
      const url =
        typeof input === "string"
          ? input
          : input instanceof URL
            ? input.toString()
            : input && typeof input.url === "string"
              ? input.url
              : undefined;
      const body = init?.body;
      if (url && typeof body === "string" && isAnthropicMessages(url)) {
        const parsed = JSON.parse(body);
        if (capCacheControl(parsed)) {
          return original(input, {
            ...init,
            body: JSON.stringify(parsed),
            headers: withoutContentLength(init.headers),
          });
        }
      }
    } catch {
      // Never let trimming break a request; fall through to the original call.
    }
    return original(input, init);
  };

  wrapped.__cacheControlCapWrapped = true;
  globalThis.fetch = wrapped;
  },
};
