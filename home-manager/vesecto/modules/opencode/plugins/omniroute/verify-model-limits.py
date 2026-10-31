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
"""Fail when model-limits.json carries an id no chain or pin consumes."""

import json
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
PROVIDER = HERE.parent.parent / "providers" / "omniroute.nix"


def pinned_ids(source: str) -> set[str]:
    """Read the pinnedIds list literal out of the provider's nix source."""
    match = re.search(r"pinnedIds\s*=\s*\[(.*?)\]", source, re.DOTALL)
    if match is None:
        sys.exit("verify-model-limits: no pinnedIds list in providers/omniroute.nix")
    return set(re.findall(r'"([^"]+)"', match.group(1)))


def main() -> int:
    limits = set(json.loads((HERE / "model-limits.json").read_text())["models"])
    chains = json.loads((HERE / "chains.json").read_text())["combos"]

    used = {model for combo in chains for model in combo["models"]}
    used |= pinned_ids(PROVIDER.read_text())

    # A missing id already throws in limitsOf, so only the spare direction needs a gate.
    orphans = sorted(limits - used)
    if orphans:
        print(
            "model-limits.json carries ids no chain or pin consumes; "
            "delete them or wire them up:",
            file=sys.stderr,
        )
        for orphan in orphans:
            print(f"  {orphan}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
