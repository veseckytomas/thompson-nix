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

// qwen3.5 vLLM template 400s unless the system message is messages[0] and unique; opencode subagents emit several — merge them on the same globalThis.fetch seam as cache-control-cap.
const LITELLM_HOST = "llm.ai.e-infra.cz";

function isChatCompletions(url) {
  try {
    const u = new URL(url);
    return u.host === LITELLM_HOST && u.pathname.endsWith("/chat/completions");
  } catch {
    return false;
  }
}

function contentToText(content) {
  if (typeof content === "string") return content;
  if (Array.isArray(content)) {
    return content
      .map((p) =>
        typeof p === "string" ? p : p && typeof p.text === "string" ? p.text : "",
      )
      .filter(Boolean)
      .join("");
  }
  return "";
}

// Collapse every system-role message into one leading system message, order-preserving for the rest.
function hoistSystem(body) {
  const msgs = body.messages;
  if (!Array.isArray(msgs) || msgs.length === 0) return false;
  const systems = [];
  const rest = [];
  for (const m of msgs) {
    if (m && m.role === "system") systems.push(m);
    else rest.push(m);
  }
  if (systems.length === 0) return false;
  // Already conformant: one system message, already at index 0.
  if (systems.length === 1 && msgs[0].role === "system") return false;
  const merged = systems
    .map((m) => contentToText(m.content))
    .filter(Boolean)
    .join("\n\n");
  body.messages = [{ role: "system", content: merged }, ...rest];
  return true;
}

// Body length changes after rewriting, so drop any caller-set content-length.
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
  id: "system-message-hoist",
  setup: async (ctx) => {
  const original = globalThis.fetch;
  // Guard against a double-wrap if opencode loads the plugin more than once.
  if (!original || original.__systemMessageHoistWrapped) return;

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
      if (url && typeof body === "string" && isChatCompletions(url)) {
        const parsed = JSON.parse(body);
        if (hoistSystem(parsed)) {
          return original(input, {
            ...init,
            body: JSON.stringify(parsed),
            headers: withoutContentLength(init.headers),
          });
        }
      }
    } catch {
      // Never let rewriting break a request; fall through to the original call.
    }
    return original(input, init);
  };

  wrapped.__systemMessageHoistWrapped = true;
  globalThis.fetch = wrapped;
  },
};
