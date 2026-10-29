#!/usr/bin/env python3
#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: vesecky@proton.me
# GitHub: veseckytomas
# GitLab: vesecky.tomas
"""Static checks for the omniroute chain config. No counts, no network, no token."""
import json
import re
import sqlite3
import sys
from pathlib import Path

# Skip flags, so `verify.py --live` works without also passing a path.
_paths = [a for a in sys.argv[1:] if not a.startswith("-")]
REPO = Path(_paths[0] if _paths else Path(__file__).resolve().parents[3]).resolve()
SKILL = Path(__file__).resolve().parent
OMNI = REPO / "home-manager/vesecto/modules/opencode/plugins/omniroute"
OMO_JSONC = REPO / "home-manager/vesecto/modules/opencode/plugins/oh-my-openagent/omo.jsonc"
DB = Path.home() / ".local/share/omniroute/data/storage.sqlite"
TAIL = "ctu/vic/GLM-5.3-Flash"

fails: list[str] = []


def check(ok: bool, label: str, detail: str = "") -> None:
    print(f"{'PASS' if ok else 'FAIL'}  {label}{'' if ok else ': ' + detail}")
    if not ok:
        fails.append(label)


def chains() -> dict[str, list[str]]:
    d = json.loads((OMNI / "chains.json").read_text())
    return {c["name"]: c["models"] for c in d["combos"]}


def consumers() -> dict[str, list[str]]:
    src = re.sub(r"(?m)^\s*//.*$", "", OMO_JSONC.read_text())
    cfg = json.loads(re.sub(r",(\s*[}\]])", r"\1", src))
    out: dict[str, list[str]] = {}
    for section in ("agents", "categories"):
        for name, val in cfg.get(section, {}).items():
            for model in val.get("models", []):
                if model.startswith("omniroute/"):
                    out.setdefault(model[len("omniroute/") :], []).append(name)
    return out


def main() -> int:
    ch = chains()
    limits = json.loads((OMNI / "model-limits.json").read_text())["models"]
    # The table is the contract: a chain missing a row is how `writing` was lost in 2026-10.
    rows = set(re.findall(r"^\| (\S+-chain) \|", (SKILL / "agent-sources.md").read_text(), re.M))

    check(rows == set(ch), "agent-sources row per chain", f"only in one: {rows ^ set(ch)}")

    missing = {m for ms in ch.values() for m in ms} - set(limits)
    check(not missing, "model-limits covers every member", str(sorted(missing)))

    bad_tail = [n for n, ms in ch.items() if ms[-1] != TAIL]
    check(not bad_tail, f"{TAIL} last", str(bad_tail))
    bad_mid = [n for n, ms in ch.items() if len(ms) > 1 and not ms[-2].startswith("litellm/")]
    check(not bad_mid, "litellm/* second-to-last", str(bad_mid))

    dupes = {n: ms for n, ms in ch.items() if len(ms) != len(set(ms))}
    check(not dupes, "no duplicate members", str(sorted(dupes)))

    cons = consumers()
    obsidian = {"didaskalos-chain", "eurybates-chain", "mageiros-chain"}
    orphans = sorted(set(ch) - set(cons) - obsidian)
    check(not orphans, "every chain has a consumer", str(orphans))

    if "--live" in sys.argv and DB.exists():
        con = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
        live = {r[0] for r in con.execute("select name from combos")}
        con.close()
        # provision-combos.sh only DELETEs combos it is about to POST, so dropped chains linger.
        stale = sorted(n for n in live - set(ch) if n.endswith("-chain"))
        check(not stale, "no stale combo in DB", f"{stale} — delete in the dashboard")

    print("\nOVERALL:", "FAIL " + ", ".join(fails) if fails else "PASS")
    return 1 if fails else 0


if __name__ == "__main__":
    raise SystemExit(main())
