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
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
OMNI = REPO / "home-manager/vesecto/modules/opencode/plugins/omniroute"
DB = Path.home() / ".local/share/omniroute/data/storage.sqlite"
TAIL = "ctu/vic/GLM-5.3-Flash"
OBSIDIAN = {"didaskalos-chain", "eurybates-chain", "mageiros-chain"}
LIGHTWEIGHT = {
    "librarian-chain",
    "explore-chain",
    "quick-chain",
    "gsd-background-chain",
}

# translation-tables.md alias rows: omo lane id -> resolved member.
ALIASES = {
    "kimi-for-coding-highspeed": "litellm/kimi-k3",
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
                if prefix is not None:
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
    "oracle-chain": [
        "gpt-5.6-sol",
        "LATEST.geminiPro",
        "gemini-3.1-pro",
        "LATEST.claudeOpus",
        "glm-5.2",
    ],
    "librarian-chain": [
        "kimi-for-coding-highspeed",
        "LATEST.gptLunaFast",
        "LATEST.claudeHaiku",
        "deepseek-flash",
        "qwen3.7-plus",
        "minimax-m2.7",
    ],
    "explore-chain": [
        "kimi-for-coding-highspeed",
        "LATEST.gptLunaFast",
        "LATEST.claudeHaiku",
        "deepseek-flash",
        "qwen3.7-plus",
        "minimax-m2.7",
    ],
    "multimodal-looker-chain": ["gpt-5.6-sol", "LATEST.kimi", "glm-4.6v", "gpt-5-nano"],
    "prometheus-chain": [
        "LATEST.claudeFable",
        "claude-fable-5-1",
        "LATEST.claudeOpus",
        "LATEST.kimi",
        "LATEST.kimiK3",
    ],
    "metis-chain": [
        "LATEST.claudeFable",
        "claude-fable-5-1",
        "LATEST.claudeOpus",
        "LATEST.kimi",
        "LATEST.kimiK3",
    ],
    "momus-chain": [
        "LATEST.gptAstra",
        "LATEST.claudeOpus",
        "LATEST.geminiPro",
        "gemini-3.1-pro",
        "glm-5.2",
    ],
    "atlas-chain": [
        "claude-sonnet-5",
        "LATEST.kimi",
        "gpt-5.6-sol",
        "minimax-m3",
        "MiniMax-M3",
        "minimax-m2.7",
    ],
    "sisyphus-junior-chain": [
        "claude-sonnet-5",
        "LATEST.kimi",
        "gpt-5.6-sol",
        "minimax-m3",
        "MiniMax-M3",
        "minimax-m2.7",
        "big-pickle",
    ],
    "ultrabrain-chain": ["LATEST.gptAstra", "gpt-5.6-sol"],
    "deep-chain": [
        "LATEST.gptSol",
        "LATEST.gptSolFast",
        "gpt-5.6-sol",
        "gpt-5.6-sol-fast",
    ],
    "deep-high-chain": ["LATEST.gptAstra"],
    "artistry-chain": ["LATEST.claudeFable", "claude-fable-5-1", "LATEST.claudeOpus", "LATEST.kimi", "LATEST.kimiK3"],
    "quick-chain": [
        "LATEST.gptLunaFast",
        "LATEST.claudeHaiku",
        "deepseek-flash",
        "qwen3.6-flash",
        "minimax-m3",
        "minimax-m2.7",
        "grok-4.20-0309-non-reasoning",
        "LATEST.glmFlash",
        "mimo-v2.6-flash",
    ],
    "unspecified-low-chain": [
        "LATEST.claudeSonnet",
        "mimo-v2.6-pro",
        "grok-4.7",
        "LATEST.glm",
        "LATEST.gptSol",
        "gpt-5.6-sol",
        "claude-sonnet-5",
        "qwen3.8-max-preview",
        "deepseek-v4-pro",
        "mimo-v2.5-pro",
    ],
    "unspecified-high-chain": ["LATEST.claudeOpus", "LATEST.glm", "LATEST.kimi", "LATEST.kimiK3"],
    "visual-engineering-chain": [
        "LATEST.geminiPro",
        "LATEST.claudeFable",
        "claude-fable-5-1",
        "LATEST.claudeOpus",
        "LATEST.kimi",
        "LATEST.kimiK3",
    ],
    "writing-chain": ["LATEST.geminiPro", "LATEST.claudeOpus", "claude-opus-4-6"],
}
# writing carries requiresAnyModel: upstream disfavors borrowing other
# families; repo keeps the litellm/ctu tail (agent-sources.md).

# Tier = catalog `agents[rep].golden` (agent-sources.md pins plan-checker to
# sonnet-family; routingTier/adaptiveTierMap disagrees and loses).
GSD_REPS = {
    "gsd-planner-chain": ("gsd-planner", "opus"),
    "gsd-plan-checker-chain": ("gsd-plan-checker", "sonnet"),
    "gsd-reasoning-chain": ("gsd-assumptions-analyzer", "opus"),
    "gsd-audit-chain": ("gsd-code-reviewer", "opus"),
    "gsd-research-chain": ("gsd-advisor-researcher", "opus"),
    "gsd-background-chain": ("gsd-codebase-mapper", "sonnet"),
}

TIER_ORDER = {
    "opus": ("opus", "sonnet", "haiku"),
    "sonnet": ("sonnet", "haiku"),
    "haiku": ("haiku",),
}
KEEP_NEWER = {
    "claude-opus-4-8": "claude-opus-5-5",
    "claude-sonnet-5": "claude-sonnet-5-5",
    "claude-haiku-4-5": "claude-haiku-5-5",
}
# Documented 2026-10 gate: 5-2 is absent from the pinned omniroute spec table.
GATED_LATEST = {"claudeFable": "claude-fable-5-1"}
_FLAKE_PATHS: dict[str, Path] = {}


def flake_path(input_name: str) -> Path:
    """Resolve a flake input's store path at runtime, never via a stale literal."""
    if input_name in _FLAKE_PATHS:
        return _FLAKE_PATHS[input_name]
    expr = f'(builtins.getFlake (toString {REPO})).inputs.{input_name}.outPath'
    result = subprocess.run(
        ["nix", "eval", "--raw", "--impure", "--expr", expr],
        check=True,
        capture_output=True,
        text=True,
    )
    _FLAKE_PATHS[input_name] = Path(result.stdout.strip())
    return _FLAKE_PATHS[input_name]


def omo_sources() -> tuple[Path, Path, Path]:
    root = flake_path("oh-my-openagent")
    src = root / "packages/model-core/src"
    return (
        src / "agent-model-requirements.ts",
        src / "category-model-requirements.ts",
        src / "latest-models.ts",
    )


def gsd_catalog() -> Path:
    return flake_path("get-shit-done-redux") / "gsd-core/bin/shared/model-catalog.json"


def declared_latest(path: Path) -> dict[str, str]:
    text = path.read_text()
    body = text.split("LATEST_MODEL_BY_FAMILY = {", 1)[1].split("} as const", 1)[0]
    return dict(re.findall(r'(\w+):\s*"([^"]+)"', body))


def validate_latest(path: Path) -> None:
    declared = declared_latest(path)
    drift = {}
    for key, upstream in declared.items():
        expected = GATED_LATEST.get(key, upstream)
        if LATEST.get(key) != expected:
            drift[key] = {"captured": LATEST.get(key), "expected": expected}
    if drift:
        raise RuntimeError(f"latest-models.ts drifted from captured LATEST: {drift}")


def key_body(text: str, key: str) -> str:
    for spelling in (f'"{key}": {{', f"{key}: {{"):
        start = text.find(spelling)
        if start != -1:
            break
    else:
        raise RuntimeError(f"pinned source has no object for {key}")
    depth = 0
    for pos in range(start, len(text)):
        match text[pos]:
            case "{":
                depth += 1
            case "}":
                depth -= 1
                if depth == 0:
                    return text[start : pos + 1]
    raise RuntimeError(f"unterminated object for key {key}")


OMO_CATEGORIES = {
    "visual-engineering",
    "ultrabrain",
    "deep-low",
    "deep-high",
    "artistry",
    "quick",
    "unspecified-low",
    "unspecified-high",
    "writing",
}


def validate_omo(paths: tuple[Path, Path, Path]) -> None:
    agents, categories, _latest = (path.read_text() for path in paths)
    validate_latest(paths[2])
    for name, rungs in OMO_CHAINS.items():
        owner = "deep-low" if name == "deep-chain" else name.removesuffix("-chain")
        text = categories if owner in OMO_CATEGORIES else agents
        body = key_body(text, owner)
        absent = [
            rung
            for rung in rungs
            if not rung.startswith("LATEST.") and f'"{rung}"' not in body
        ]
        if absent:
            raise RuntimeError(f"{name}: pinned {owner} no longer declares rungs {absent}")
        families = {rung.split(".", 1)[1] for rung in rungs if rung.startswith("LATEST.")}
        missing = sorted(
            fam for fam in families if f"LATEST_MODEL_BY_FAMILY.{fam}" not in body
        )
        if missing:
            raise RuntimeError(f"{name}: pinned {owner} no longer declares families {missing}")


def gsd_data() -> dict:
    return json.loads(gsd_catalog().read_text())


def gsd_models(tier: str) -> list[str]:
    data = gsd_data()
    defaults = data["runtimeTierDefaults"]["claude"]
    return [
        KEEP_NEWER.get(str(defaults[name]["model"]), str(defaults[name]["model"]))
        for name in TIER_ORDER[tier]
    ]


def validate_gsd() -> None:
    data = gsd_data()
    agents = data["agents"]
    drift = []
    for chain, (agent, tier) in GSD_REPS.items():
        entry = agents.get(agent)
        if entry is None or entry["golden"] != tier:
            drift.append(chain)
    if drift:
        raise RuntimeError(f"GSD representative/golden-tier drift: {drift}")
    for tier in TIER_ORDER:
        if tier not in data["runtimeTierDefaults"]["claude"]:
            raise RuntimeError(f"GSD runtimeTierDefaults.claude missing {tier}")


def validate_sources() -> None:
    validate_omo(omo_sources())
    validate_gsd()


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


def current_chains() -> dict[str, list[str]]:
    data = json.loads((OMNI / "chains.json").read_text())
    return {combo["name"]: combo["models"] for combo in data["combos"]}


def catalog_has(member: str, cat: dict[str, set[str]]) -> bool:
    prefix, model = member.split("/", 1)
    return model in cat[prefix]


OMNI_CURRENT = Path.home() / ".local/share/omniroute/current/node_modules/omniroute"


def spec_ids() -> set[str]:
    """Shapable ids from the installed omniroute@<pin> spec table (keep-newer
    gate): direct entries and context-window rows count; dotted catalog ids
    resolve through alias rows to the dashed entry, so normalize before
    comparing."""
    text = (OMNI_CURRENT / "src/shared/constants/modelSpecs.ts").read_text()
    ids = set(re.findall(r'^\s{2}"([^"]+)": \{', text, re.M))
    ids |= set(re.findall(r'\["[^/"]+/([^/"]+)", \d+\]', text))
    return {i.replace(".", "-") for i in ids}


def shapable(member: str, specs: set[str], known: set[str] | None = None) -> bool:
    """Gateway shapes suffixed variants by prefix-matching the base entry, so
    a member is shapable when its normalized id or any dash-truncated prefix
    of it is in the spec table (or it is already a proven member)."""
    if known and member in known:
        return True
    ident = norm(member.split("/", 1)[-1])
    while ident:
        if ident in specs:
            return True
        if "-" not in ident:
            return False
        ident = ident.rsplit("-", 1)[0]
    return False


def alias_target(target: str) -> str:
    """Report the id a user compares against, keeping the vic/ namespace."""
    return target.removeprefix("litellm/").removeprefix("cx/").removeprefix("ctu/")


def build_proposal(cat: dict[str, set[str]]) -> dict:
    validate_sources()
    current = current_chains()
    specs = spec_ids()
    used = {rung for rungs in OMO_CHAINS.values() for rung in rungs}
    substitutions = {
        source: alias_target(target)
        for source, target in ALIASES.items()
        if source in used and target != "LUNA_FAST" and alias_target(target) != source
    }
    chains: dict[str, dict] = {}
    for name, info in derive(cat).items():
        members = info["members"]
        direct = [
            member
            for prefix in ("cx/", "gh/", "antigravity/")
            for member in members
            if member.startswith(prefix)
        ]
        # Owner decision (2026-11): re-place every current antigravity member
        # as a mid-chain fallback, not just opus-thinking — the strict order
        # drops sonnet-4-6 fall-backs the previous run placed.
        ag_fallback = [
            member
            for member in current.get(name, [])
            if member.startswith("antigravity/")
            and catalog_has(member, cat)
            and shapable(member, specs)
        ]
        litellm = next(
            (member for member in members if member.startswith("litellm/")),
            "litellm/glm-5.3-flash" if name in LIGHTWEIGHT else "litellm/glm-5.3",
        )
        chains[name] = {**info, "members": [*direct, *ag_fallback, litellm, TAIL]}
    for name in OBSIDIAN:
        chains[name] = {"members": current[name], "no_route": [], "src": "none:preserved"}
    known = {member for members in current.values() for member in members}
    spec_gated = {
        member: sorted(
            name for name, info in chains.items()
            if member in info["members"] and member not in known
        )
        for member in sorted(
            {m for info in chains.values() for m in info["members"]}
        )
        if member not in known and not shapable(member, specs, known)
    }
    if spec_gated:
        raise RuntimeError(f"new members unshapable by pinned omniroute spec table: {spec_gated}")
    spec_check = {
        member: shapable(member, specs, known)
        for member in sorted({m for info in chains.values() for m in info["members"]})
    }
    missing = sorted(
        member
        for info in chains.values()
        for member in info["members"]
        if not catalog_has(member, cat)
    )
    if missing:
        raise RuntimeError(f"proposal contains unavailable catalog members: {missing}")
    diff = {
        name: {
            "added": [
                member for member in info["members"] if member not in current.get(name, [])
            ],
            "removed": [
                member for member in current.get(name, []) if member not in info["members"]
            ],
        }
        for name, info in chains.items()
    }
    return {
        "chains": chains,
        "diff": diff,
        "substitutions": substitutions,
        "spec_check": spec_check,
        "spec_gated": spec_gated,
    }


def owned_tail_errors(proposal: dict) -> list[str]:
    """One litellm member sits just before the CTU tail; antigravity
    fallbacks may sit mid-chain, so positionally assert only the tail."""
    errors = []
    for name, info in proposal["chains"].items():
        if name in OBSIDIAN:
            continue
        members = info["members"]
        litellm = [m for m in members if m.startswith("litellm/")]
        if len(litellm) != 1 or members[-2] != litellm[0] or members[-1] != TAIL:
            errors.append(name)
    return errors


def main() -> int:
    proposal = build_proposal(catalog())
    json.dump(proposal, sys.stdout, indent=2, sort_keys=True)
    print()
    return 0


SELFTEST = [
    # (label, fn, expected)
    ("alias kimi-for-coding-highspeed -> litellm/kimi-k3",
     lambda: resolve_rung("kimi-for-coding-highspeed", catalog()), "litellm/kimi-k3"),
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
    ("proposal contains 26 owned chains plus three preserved Obsidian chains",
     lambda: len(build_proposal(catalog())["chains"]), 29),
    ("every owned chain has exactly one litellm member before the CTU tail",
     lambda: owned_tail_errors(build_proposal(catalog())), []),
    ("cross-product aliases are reported",
     lambda: build_proposal(catalog())["substitutions"].get("glm-4.6v"), "glm-5.3-flash"),
    ("GSD tiers come from catalog golden (plan-checker sonnet, audit opus)",
     lambda: gsd_models("sonnet"), ["claude-sonnet-5-5", "claude-haiku-5-5"]),
    ("spec table covers every new member or the run fails",
     lambda: build_proposal(catalog())["spec_gated"], {}),
    ("current antigravity fallbacks are re-placed before the litellm slot",
     lambda: sorted(
         (n, m)
         for n, ms in current_chains().items()
         for m in ms
         if m.startswith("antigravity/")
         and catalog_has(m, catalog())
         and shapable(m, spec_ids())
         and m not in build_proposal(catalog())["chains"][n]["members"]
     ), []),
]


def selftest() -> int:
    fails = 0
    for label, fn, expected in SELFTEST:
        try:
            got = fn()
        except (RuntimeError, OSError, subprocess.CalledProcessError) as error:
            got = f"ERROR {error}"
        ok = got == expected
        print(f"{'PASS' if ok else 'FAIL'}  {label}" + ("" if ok else f": got {got!r}"))
        if not ok:
            fails += 1
    print("\nOVERALL:", "PASS" if not fails else f"{fails} FAIL")
    return 1 if fails else 0


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "proposal"
    raise SystemExit(selftest() if mode == "selftest" else main())
