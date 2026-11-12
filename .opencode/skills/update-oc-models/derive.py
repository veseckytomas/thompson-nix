#!/usr/bin/env python3
#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
"""Derive proposed chain members from the live catalog + pinned upstream.

Data: OmniRoute SQLite (syncedAvailableModels + customModels, merged per
prefix). Rules: agent-sources.md (owner per chain), translation-tables.md
(aliases, keep-newer, order, excluded variants, litellm+ctu tail).

Modes:
  proposal   print per-chain member proposal (default)
  selftest   run documented rule cases, exit 0 when all pass
"""

import json
import re
import sqlite3
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
OMNI = REPO / "home-manager/vesecto/modules/opencode/plugins/omniroute"
DB = Path.home() / ".local/share/omniroute/data/storage.sqlite"
TAIL = "ctu/vic/GLM-5.3-Flash"

# translation-tables.md alias rows: omo lane id -> resolved member.
ALIASES = {
    "kimi-for-coding-highspeed": "litellm/kimi-k3.1-pro",
    "deepseek-flash": "litellm/deepseek-v4.1-flash",
    "deepseek-v4-pro": "litellm/deepseek",
    "glm-5.2": "litellm/glm-5.3",
    "glm-4.6v": "litellm/glm-5.3-flash",
    "qwen3.6-flash": "ctu/vic/Qwen3.8-Flash-Next",
    "qwen3.7-plus": "ctu/vic/Qwen3.8-27B",
    "gpt-6-luna-fast": "LUNA_FAST",
    "gpt-5.6-sol-fast": "cx/gpt-5.6-sol",
    "gpt-6.1-sol-fast": "cx/gpt-6.1-sol",
    "gpt-5-nano": "cx/gpt-5.6-luna",
}

# packages/model-core/src/latest-models.ts, pinned snapshot. claudeFable
# held at 5-1: 5-2 gated on omniroute spec table (grep count 0) per
# translation-tables.md keep-newer gate. Bump ids here only when the pin
# moves and the gate passes.
LATEST = {
    "claudeOpus": "claude-opus-5-5",
    "claudeSonnet": "claude-sonnet-5-5",
    "claudeHaiku": "claude-haiku-5-5",
    "claudeFable": "claude-fable-5-1",
    "gptAstra": "gpt-6-astra",
    "gptSol": "gpt-6.1-sol",
    "gptSolFast": "gpt-6.1-sol-fast",
    "gptLunaFast": "gpt-6-luna-fast",
    "glm": "glm-5.3",
    "glmFlash": "glm-5.3-flash",
    "kimi": "kimi-k3.1-pro",
    "kimiK3": "kimi-k3",
    "geminiPro": "gemini-4-argon",
}

# Never auto-select substitute variants (translation-tables.md).
EXCLUDED_SUB = re.compile(
    r"-(tiered|lite|disabled|utility|preview|reserve)$|^(exec-agent|copilot-search|trajectory)"
)
DATE_STAMP = re.compile(r"-20\d{6}$")

# syncedAvailableModels keys are <provider>:<conn>; customModels keys are
# bare connection ids. Both merge into one prefix map or `cc` loses most
# models.
PREFIX_BY_KEY = {
    "claude": "cc",
    "codex": "cx",
    "antigravity": "antigravity",
}
CUSTOM_PREFIX_BY_KEY = {
    "anthropic-compatible-cc-e968a738-66e3-43db-a12c-66be02acc136": "cc",
    "github": "gh",
    "openai-compatible-chat-1b0f4418-f336-4a99-a33a-3e9cdba64b67": "ctu",
}
# synced keys carry ":<connId>" suffix; match on the static part.
CUSTOM_PREFIX_CONTAINS = {
    "openai-compatible-chat-1b0f4418": "ctu",
    "openai-compatible-chat-4acfd047": "litellm",
}
# Bare vic/* ids always land on ctu regardless of the connection key.
CTU_IDS = re.compile(r"^vic/")


def catalog() -> dict[str, set[str]]:
    out: dict[str, set[str]] = {}
    con = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    sqls = (
        "select key, value from key_value where namespace='syncedAvailableModels'",
        "select key, value from key_value where namespace='customModels'",
    )
    for sql in sqls:
        for key, value in con.execute(sql):
            data = json.loads(value)
            models = (
                data.get("models", [])
                if isinstance(data, dict)
                else (data if isinstance(data, list) else [])
            )
            for m in models:
                mid = m.get("id") if isinstance(m, dict) else None
                if not mid:
                    continue
                if CTU_IDS.match(mid):
                    prefix = "ctu"
                elif key in CUSTOM_PREFIX_BY_KEY:
                    prefix = CUSTOM_PREFIX_BY_KEY[key]
                elif key.startswith("github"):
                    prefix = "gh"
                else:
                    static = key.split(":")[0]
                    for frag, pfx in CUSTOM_PREFIX_CONTAINS.items():
                        if static.startswith(frag):
                            prefix = pfx
                            break
                    else:
                        prefix = PREFIX_BY_KEY.get(static, static)
                out.setdefault(prefix, set()).add(mid)
    con.close()
    for need in ("litellm", "gh", "cx", "cc", "ctu", "antigravity"):
        if need not in out:
            sys.exit(f"derive.py: catalog extraction failed (missing {need})")
    return out


def norm(id_: str) -> str:
    """Compare omo ids (dashed) against catalog ids (dot/ver variants)."""
    return id_.replace(".", "-")


def resolve_family(target: str, cat: dict[str, set[str]]) -> str | None:
    """LATEST family -> `<prefix>/<id>`, picking the first prefix, in
    translation-tables order (cc pinned-only; the three obsidian chains are
    the sole cc exception and are maintained by hand, not derived; direct cx;
    gh; antigravity; litellm), that carries an available equivalent (exact id,
    keep-newer successor, or dotted twin)."""
    bare = target.split("/", 1)[-1]
    modernized = DATE_STAMP.sub("", bare)
    upgraded = {norm(modernized), norm(bare)}
    order = ["cx", "gh", "antigravity", "litellm"]
    for pfx in order:
        for mid in sorted(cat[pfx]):
            if norm(mid) in upgraded:
                return f"{pfx}/{mid}"
    return None


def resolve_rung(model: str, cat: dict[str, set[str]]) -> str | None:
    """One upstream (model) -> omniroute member id, or None (no route).

    LUNA_FAST resolves to cx/gpt-6-luna (fast tier is the same lane).
    Excluded substitute variants (moq variants, exec-agent/copilot-search/
    trajectory families) resolve None and are reported."""
    if model.startswith("LATEST."):
        fam = model.split(".", 1)[1]
        if fam not in LATEST:
            return None
        target = LATEST[fam]
        if "/" in target:
            return target if target.startswith("ctu/") else None
        if target in ALIASES:
            a = ALIASES[target]
            return a if a != "LUNA_FAST" else "cx/gpt-6-luna"
        return resolve_family(target, cat)
    if model in ALIASES:
        a = ALIASES[model]
        if a == "LUNA_FAST":
            return "cx/gpt-6-luna"
        return a
    if EXCLUDED_SUB.search(model):
        return None
    if model.startswith("vic/"):
        return f"ctu/{model}"
    bare_n = norm(DATE_STAMP.sub("", model))
    for pfx in ("cx", "gh", "antigravity", "litellm", "ctu"):
        if norm(model) in {norm(m) for m in cat[pfx]}:
            match = next(m for m in sorted(cat[pfx]) if norm(m) == norm(model))
            return f"{pfx}/{match}"
        if bare_n in {norm(m) for m in cat[pfx]}:
            match = next(m for m in sorted(cat[pfx]) if norm(m) == bare_n)
            return f"{pfx}/{match}"
    return None


# ---------------------------------------------------------------------------
# Upstream declarations captured from the pinned sources:
#   omo: agent-model-requirements.ts / category-model-requirements.ts
#   gsd: gsd-core/bin/shared/model-catalog.json agents + runtimeTierDefaults
# Rows: (chain, [rungs best-first], source)
# ---------------------------------------------------------------------------
CLAUDE = ["LATEST.claudeOpus", "LATEST.claudeSonnet", "LATEST.claudeHaiku"]
OMO_CHAINS = {
    "sisyphus-chain": [
        "LATEST.claudeOpus", "LATEST.kimi", "LATEST.kimiK3",
        "gpt-5.6-sol", "glm-5.2", "big-pickle",
    ],
    "hephaestus-chain": ["gpt-6-sol", "gpt-5.6-sol"],
    "oracle-chain": ["gpt-5.6-sol", "LATEST.geminiPro", "gemini-3.1-pro", "LATEST.claudeOpus", "glm-5.2"],
    "librarian-chain": ["kimi-for-coding-highspeed", "LATEST.gptLunaFast", "LATEST.claudeHaiku", "deepseek-flash", "qwen3.7-plus", "minimax-m2.7"],
    "explore-chain": ["kimi-for-coding-highspeed", "LATEST.gptLunaFast", "LATEST.claudeHaiku", "deepseek-flash", "qwen3.7-plus", "minimax-m2.7"],
    "multimodal-looker-chain": ["gpt-5.6-sol", "LATEST.kimi", "glm-4.6v", "gpt-5-nano"],
    "prometheus-chain": ["LATEST.claudeFable", "claude-fable-5-1", "LATEST.claudeOpus", "LATEST.kimi", "LATEST.kimiK3"],
    "metis-chain": ["LATEST.claudeFable", "claude-fable-5-1", "LATEST.claudeOpus", "LATEST.kimi", "LATEST.kimiK3"],
    "momus-chain": ["LATEST.gptAstra", "LATEST.claudeOpus", "LATEST.geminiPro", "gemini-3.1-pro", "glm-5.2"],
    "atlas-chain": ["claude-sonnet-5", "LATEST.kimi", "gpt-5.6-sol", "minimax-m3", "MiniMax-M3", "minimax-m2.7"],
    "sisyphus-junior-chain": ["claude-sonnet-5", "LATEST.kimi", "gpt-5.6-sol", "minimax-m3", "MiniMax-M3", "minimax-m2.7", "big-pickle"],
    "ultrabrain-chain": ["LATEST.gptAstra", "gpt-5.6-sol"],
    "deep-chain": ["LATEST.gptSol", "LATEST.gptSolFast", "gpt-5.6-sol", "gpt-5.6-sol-fast", "gpt-5.6-sol-fast"],
    "deep-high-chain": ["LATEST.gptAstra"],
    "artistry-chain": ["LATEST.claudeFable", "claude-fable-5-1", "LATEST.claudeOpus", "LATEST.kimi", "LATEST.kimiK3"],
    "quick-chain": ["LATEST.gptLunaFast", "LATEST.claudeHaiku", "deepseek-flash", "qwen3.6-flash", "minimax-m3", "MiniMax-M3", "minimax-m2.7", "grok-4.20-0309-non-reasoning", "LATEST.glmFlash", "mimo-v2.6-flash"],
    "unspecified-low-chain": ["LATEST.claudeSonnet", "mimo-v2.6-pro", "grok-4.7", "LATEST.glm", "LATEST.gptSol", "gpt-5.6-sol", "claude-sonnet-5", "qwen3.8-max-preview", "deepseek-v4-pro", "mimo-v2.5-pro"],
    "unspecified-high-chain": ["LATEST.claudeOpus", "LATEST.glm", "LATEST.kimi", "LATEST.kimiK3", "big-pickle"],
    "visual-engineering-chain": ["LATEST.geminiPro", "LATEST.claudeFable", "claude-fable-5-1", "LATEST.claudeOpus", "LATEST.kimi", "LATEST.kimiK3"],
    "writing-chain": ["LATEST.geminiPro", "LATEST.claudeOpus", "claude-opus-4-6"],
}
# writing carries requiresAnyModel: upstream disfavors borrowing other
# families; repo keeps the litellm/ctu tail (agent-sources.md).

GSD_REPS = {  # chain -> agent + tier (adaptiveTierMap via routingTier/profile)
    "gsd-planner-chain": ("gsd-planner", "opus"),
    "gsd-plan-checker-chain": ("gsd-plan-checker", "sonnet"),
    "gsd-reasoning-chain": ("gsd-assumptions-analyzer", "opus"),
    "gsd-audit-chain": ("gsd-code-reviewer", "opus"),
    "gsd-research-chain": ("gsd-advisor-researcher", "opus"),
    "gsd-background-chain": ("gsd-codebase-mapper", "sonnet"),
}


def gsd_models(tier: str) -> list[str]:
    # runtimeTierDefaults claude rungs; tier ids are gh-catalog
    # equivalents: opus->5.5 opus, sonnet->5.5 sonnet, haiku->5.5 haiku.
    return {
        "opus": ["claude-opus-5.5", "claude-sonnet-5.5", "claude-haiku-5.5"],
        "sonnet": ["claude-sonnet-5.5", "claude-haiku-5.5"],
        "haiku": ["claude-haiku-5.5"],
    }[tier]


def derive(cat: dict[str, set[str]]) -> dict[str, dict]:
    chains: dict[str, dict] = {}
    for name, rungs in OMO_CHAINS.items():
        members, no_route = [], []
        for r in rungs:
            member = resolve_rung(r, cat)
            if member is None:
                no_route.append(r)
            elif member not in members:
                members.append(member)
        chains[name] = {"members": members, "no_route": no_route, "src": "omo"}
    for name, (agent, tier) in GSD_REPS.items():
        members, no_route = [], []
        for m in gsd_models(tier):
            member = resolve_rung(m, cat)
            if member is None:
                no_route.append(m)
            elif member not in members:
                members.append(member)
        chains[name] = {"members": members, "no_route": no_route, "src": f"gsd:{agent}"}
    return chains


def main() -> int:
    cat = catalog()
    chains = derive(cat)
    for name, info in chains.items():
        print(f"{name} [{info['src']}]")
        for m in info["members"]:
            print(f"  + {m}")
        for r in info["no_route"]:
            print(f"  ? no-route: {r}")
    return 0


SELFTEST = [
    # (label, fn, expected)
    ("alias kimi-for-coding-highspeed -> litellm/kimi-k3.1-pro",
     lambda: resolve_rung("kimi-for-coding-highspeed", catalog()), "litellm/kimi-k3.1-pro"),
    ("alias deepseek-flash -> litellm/deepseek-v4.1-flash",
     lambda: resolve_rung("deepseek-flash", catalog()), "litellm/deepseek-v4.1-flash"),
    ("alias glm-5.2 -> litellm/glm-5.3",
     lambda: resolve_rung("glm-5.2", catalog()), "litellm/glm-5.3"),
    ("alias glm-4.6v -> litellm/glm-5.3-flash (silent substitution, reported)",
     lambda: resolve_rung("glm-4.6v", catalog()), "litellm/glm-5.3-flash"),
    ("alias qwen3.7-plus -> ctu/vic/Qwen3.8-27B",
     lambda: resolve_rung("qwen3.7-plus", catalog()), "ctu/vic/Qwen3.8-27B"),
    ("alias gpt-6-luna-fast -> cx/gpt-6-luna",
     lambda: resolve_rung("LATEST.gptLunaFast", catalog()), "cx/gpt-6-luna"),
    ("LATEST.claudeFable pinned at 5-1, resolved via gh",
     lambda: resolve_rung("LATEST.claudeFable", catalog()), "gh/claude-fable-5.1"),
    ("LATEST.claudeOpus keep-newer -> gh/claude-opus-5.5",
     lambda: resolve_rung("LATEST.claudeOpus", catalog()), "gh/claude-opus-5.5"),
    ("LATEST.gptSol keep-newer 6.1 over 5.6 -> cx/gpt-6.1-sol",
     lambda: resolve_rung("LATEST.gptSol", catalog()), "cx/gpt-6.1-sol"),
    ("gpt-reserve excluded (substitute variant)",
     lambda: resolve_rung("gpt-reserve", catalog()), None),
    ("copilot-search-a excluded (family ban)",
     lambda: resolve_rung("copilot-search-a", catalog()), None),
    ("gemini-4-argon-family disabled variant excluded",
     lambda: resolve_rung("gemini-4-argon-disabled", catalog()), None),
    ("vic/* lands on ctu",
     lambda: resolve_rung("vic/Gemma-4-26B-A4B", catalog()), "ctu/vic/Gemma-4-26B-A4B"),
]


def selftest() -> int:
    cat = catalog()
    fails = 0
    for label, fn, expected in SELFTEST:
        try:
            got = fn()
        except Exception as e:
            got = f"ERROR {e}"
        ok = got == expected
        print(f"{'PASS' if ok else 'FAIL'}  {label}" + ("" if ok else f": got {got!r}"))
        if not ok:
            fails += 1
    print("\nOVERALL:", "PASS" if not fails else f"{fails} FAIL")
    return 1 if fails else 0


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "proposal"
    raise SystemExit(selftest() if mode == "selftest" else main())
