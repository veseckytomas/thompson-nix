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
#
# Drops @code-yeongyu/senpi: unimported by the nix profile, but its install graph wants registry manifests bun2nix's tarball-only cache cannot serve.
import json
import re
import sys
from pathlib import Path

KEY = "@code-yeongyu/senpi"
EXPECT = 8

MANIFESTS = [
    "package.json",
    "packages/omo-native/package.json",
    "packages/omo-senpi/package.json",
    "packages/senpi-task/package.json",
]

FIELDS = [
    "dependencies",
    "devDependencies",
    "peerDependencies",
    "optionalDependencies",
    "peerDependenciesMeta",
    "optionalPeers",
    "trustedDependencies",
]

# build-nodes-nix-profile.patch excludes these by name, a denylist that fails open on a rename.
EXCLUDED_NODES = ["codex-plugin", "senpi-plugin"]


def die(msg):
    print(f"strip-senpi: FATAL {msg}", file=sys.stderr)
    sys.exit(1)


def strip_manifests(root):
    total = 0
    for name in MANIFESTS:
        path = root / name
        if not path.is_file():
            die(f"manifest vanished upstream: {name}")
        data = json.loads(path.read_text())
        removed = 0
        for field in FIELDS:
            section = data.get(field)
            # Exact key, never substring: the npm:@code-yeongyu/senpi-tui aliases are other packages that resolve offline.
            if isinstance(section, dict) and KEY in section:
                section.pop(KEY)
                removed += 1
                if not section:
                    del data[field]
            elif isinstance(section, list) and KEY in section:
                section.remove(KEY)
                removed += 1
        path.write_text(json.dumps(data, indent=2) + "\n")
        print(f"  stripped {removed} from {name}")
        total += removed
    return total


def assert_excluded_nodes_resolve(root):
    path = root / "script/build-nodes.ts"
    if not path.is_file():
        die("script/build-nodes.ts is gone; the nix build profile has no anchor")
    src = path.read_text()
    ids = re.findall(r'\{\s*id:\s*"([^"]+)"', src)
    if not ids:
        die("no node ids parsed from build-nodes.ts; its shape changed")
    # Present only post-patch, so cross-check the real constant when it is visible.
    declared = re.search(r"NIX_EXCLUDED_NODES[^=]*=\s*\[([^\]]*)\]", src)
    if declared:
        names = re.findall(r'"([^"]+)"', declared.group(1))
        if sorted(names) != sorted(EXCLUDED_NODES):
            die(f"patch excludes {names} but this script expects {EXCLUDED_NODES}")
    missing = [n for n in EXCLUDED_NODES if n not in ids]
    if missing:
        die(
            f"excluded node(s) {missing} no longer exist among {len(ids)} ids; "
            "upstream renamed them and the exclusion now fails open"
        )
    print(f"  nodes resolve ({'cross-checked' if declared else 'pre-patch'}): {EXCLUDED_NODES} among {len(ids)} ids")


def main():
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    assert_excluded_nodes_resolve(root)
    total = strip_manifests(root)
    if total != EXPECT:
        die(
            f"expected {EXPECT} senpi declarations, removed {total}; "
            "upstream changed its senpi wiring -- recount and update EXPECT"
        )
    print(f"strip-senpi: OK {total}/{EXPECT} declarations removed")


if __name__ == "__main__":
    main()
