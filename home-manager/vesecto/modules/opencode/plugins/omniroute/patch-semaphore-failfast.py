#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
#
# A combo request whose only active concurrency gate is a capped account (litellm's 4 slots) fails fast to the next chain member instead of queueing for RATE_LIMIT_MAX_WAIT_MS.
import os
import re
import sys
from pathlib import Path

SERVER = "dist/.build/next/server"
SIGNATURE = b"requestQueue.maxQueueDepth,signal:"
MARKER = "__omniCombo"
ID = r"[A-Za-z_$][\w$]*"

# chatCore's own isCombo parameter, in scope where it builds the executeProviderRequest deps literal.
CORE_PARAM = re.compile(rf"isCombo:({ID})=!1,")
DEPS = re.compile(rf"(=\{{)(agentGoalPolicy:{ID},assertManagedLeaseFence:)")
EPR = re.compile(
    rf"(async function {ID}\(({ID}),{ID}=\2\.effectiveModel,{ID}=!1,{ID}\)\{{let\{{)(agentGoalPolicy:)"
)
# The composite acquireMany call over the global, provider, account and model gates.
GATE = re.compile(
    rf"\[\{{key:\"global\",maxConcurrency:({ID})\.requestQueue\.globalConcurrentRequests\}},"
    rf"\{{key:`provider:\$\{{{ID}\}}`,maxConcurrency:({ID})\}},"
    rf"\{{key:({ID})\|\|\"\",maxConcurrency:\3\?({ID}):null\}},"
    rf"\{{key:({ID})\.key\|\|\"\",maxConcurrency:\5\.key\?\5\.maxConcurrency:null\}}\],"
    rf"\{{timeoutMs:{ID},maxQueueSize:\1\.requestQueue\.maxQueueDepth,signal:{ID}\.signal\}}\)"
)


def die(msg):
    print(f"patch-semaphore-failfast: FATAL {msg}", file=sys.stderr)
    sys.exit(1)


def one(rx, text, what, name):
    hits = list(rx.finditer(text))
    if len(hits) != 1:
        die(
            f"{what} anchor not unique in {name} ({len(hits)} hits) - upstream drifted, re-derive the patch"
        )
    return hits[0]


def fail_fast(gate):
    q, provider_cap, account_key, account_cap, model_gate = gate.groups()
    return (
        f"{MARKER}&&!!{account_key}&&+{account_cap}>0"
        f"&&!(+{q}.requestQueue.globalConcurrentRequests>0)&&!(+{provider_cap}>0)"
        f"&&!({model_gate}.key&&+{model_gate}.maxConcurrency>0)"
    )


def patch(text, name):
    combo = one(CORE_PARAM, text, "isCombo param", name).group(1)
    one(DEPS, text, "deps literal", name)
    one(EPR, text, "executeProviderRequest head", name)
    one(GATE, text, "concurrency gate", name)
    text = DEPS.sub(
        lambda m: f"{m.group(1)}{MARKER}:{combo},{m.group(2)}", text, count=1
    )
    text = EPR.sub(lambda m: f"{m.group(1)}{MARKER},{m.group(3)}", text, count=1)
    return GATE.sub(
        lambda m: f"{m.group(0)[:-2]},failFast:{fail_fast(m)}}})", text, count=1
    )


def main():
    if len(sys.argv) != 2:
        die("usage: patch-semaphore-failfast.py <omniroute package root>")
    root = Path(sys.argv[1]) / SERVER
    if not root.is_dir():
        die(
            f"{SERVER} vanished upstream - the compiled server moved, re-derive the patch"
        )
    targets = []
    for dirpath, _, files in os.walk(root):
        for name in files:
            if name.endswith(".js"):
                path = Path(dirpath) / name
                data = path.read_bytes()
                if SIGNATURE in data:
                    targets.append((path, data.decode()))
    if not targets:
        die(
            "no compiled chunk carries the concurrency gate - upstream drifted, re-derive the patch"
        )
    todo = [(path, text) for path, text in targets if MARKER not in text]
    if not todo:
        print(f"patch-semaphore-failfast: OK already applied ({len(targets)} chunks)")
        return
    # Patch every chunk in memory first so a drifted one leaves the whole tree untouched.
    patched = [(path, patch(text, path.name)) for path, text in todo]
    for path, text in patched:
        tmp = path.with_name(path.name + ".failfast-tmp")
        tmp.write_text(text, encoding="utf-8")
        os.replace(tmp, path)
    print(
        f"patch-semaphore-failfast: OK applied ({len(patched)} of {len(targets)} chunks)"
    )


if __name__ == "__main__":
    main()
