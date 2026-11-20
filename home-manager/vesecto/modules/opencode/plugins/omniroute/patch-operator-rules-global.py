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
# Turbopack compiles providerErrorRules.ts into one module copy per layer, so operator rules loaded at boot never reach the chat route's copy; this gives every copy one globalThis store.
import os
import re
import sys
from pathlib import Path

SERVER = "dist/.build/next/server"
SIGNATURE = b'.reason??"quota_exhausted",scope:'
MARKER = "__omniroute_operatorProviderErrorRules__"
ID = r"[A-Za-z_$][\w$]*"

READER = re.compile(rf"\(({ID})\?\?({ID})\)\?\.\[{ID}\];")


def declaration(store):
    return re.compile(rf"(?<=,){re.escape(store)}=\{{\}}(?=[,;])")


def setter(store):
    s = re.escape(store)
    return re.compile(
        rf"function\(({ID})\)\{{if\({s}=\{{\}},\1\)for\(let\[({ID}),({ID})\]of Object\.entries\(\1\)\)"
        rf"Array\.isArray\(\3\)&&\3\.length>0&&\({s}\[\2\.toLowerCase\(\)\]=\3\)\}}"
    )


def die(msg):
    print(f"patch-operator-rules-global: FATAL {msg}", file=sys.stderr)
    sys.exit(1)


def one(rx, text, what, name):
    hits = list(rx.finditer(text))
    if len(hits) != 1:
        die(
            f"{what} anchor not unique in {name} ({len(hits)} hits) - upstream drifted, re-derive the patch"
        )
    return hits[0]


def patch(text, name):
    store = one(READER, text, "rule store reader", name).group(2)
    decl = declaration(store)
    one(decl, text, "rule store declaration", name)
    rx = setter(store)
    one(rx, text, "rule store setter", name)
    text = decl.sub(f"{store}=(globalThis.{MARKER}??={{}})", text, count=1)
    # Reassigning would detach this copy from the shared store, so the setter empties it in place.
    clear = f"if(Object.keys({store}).forEach(__omniKey=>delete {store}[__omniKey]),"
    return rx.sub(
        lambda m: m.group(0).replace(f"if({store}={{}},", clear, 1), text, count=1
    )


def main():
    if len(sys.argv) != 2:
        die("usage: patch-operator-rules-global.py <omniroute package root>")
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
            "no compiled chunk carries the operator rule store - upstream drifted, re-derive the patch"
        )
    todo = [(path, text) for path, text in targets if MARKER not in text]
    if not todo:
        print(
            f"patch-operator-rules-global: OK already applied ({len(targets)} chunks)"
        )
        return
    # Patch every chunk in memory first so a drifted one leaves the whole tree untouched.
    patched = [(path, patch(text, path.name)) for path, text in todo]
    for path, text in patched:
        tmp = path.with_name(path.name + ".rules-tmp")
        tmp.write_text(text, encoding="utf-8")
        os.replace(tmp, path)
    print(
        f"patch-operator-rules-global: OK applied ({len(patched)} of {len(targets)} chunks)"
    )


if __name__ == "__main__":
    main()
