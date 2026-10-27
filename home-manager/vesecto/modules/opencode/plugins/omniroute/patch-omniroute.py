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
# Teaches 3.8.51's learned-effort parser Kimi's intro and strips only `k=v` annotations before tokenization.
import sys
from pathlib import Path

TARGET = "open-sse/services/learnedReasoningEffortCaps.ts"
MARKER = "supports (?:reasoning|thinking)_effort values?"
INTRO_ANCHOR = (
    "const LIST_INTRO = /(?:expected one of|supported (?:types|values) are|please use)[:\\s]*([^.]+)/i;\n"
)
INTRO_REPLACEMENT = (
    "const LIST_INTRO = /(?:expected one of|supported (?:types|values) are|please use|supports "
    "(?:reasoning|thinking)_effort values?)[:\\s]*([^.]+)/i;\n"
)
PIPELINE_ANCHOR = "  const tokens = match[1]\n    .split(/,|\\||\\b(?:and|or)\\b|&/i)\n"
PIPELINE_REPLACEMENT = (
    "  const tokens = match[1]\n"
    '    .replace(/\\([^)=]*=[^)]*\\)/g, "")\n'
    "    .split(/,|\\||\\b(?:and|or)\\b|&/i)\n"
)


def die(msg):
    print(f"patch-omniroute: FATAL {msg}", file=sys.stderr)
    sys.exit(1)


def main():
    if len(sys.argv) != 2:
        die("usage: patch-omniroute.py <omniroute package root>")
    path = Path(sys.argv[1]) / TARGET
    if not path.is_file():
        die(f"{TARGET} vanished upstream - the learned-effort parser has no anchor")
    text = path.read_text()
    if MARKER in text:
        print("patch-omniroute: OK already applied")
        return
    anchors = ((INTRO_ANCHOR, "LIST_INTRO"), (PIPELINE_ANCHOR, "token pipeline"))
    for anchor, name in anchors:
        if text.count(anchor) != 1:
            die(f"{name} anchor not unique in {TARGET} ({text.count(anchor)} hits) - upstream drifted, re-derive the parser patch")
    text = text.replace(INTRO_ANCHOR, INTRO_REPLACEMENT, 1)
    path.write_text(text.replace(PIPELINE_ANCHOR, PIPELINE_REPLACEMENT, 1))
    print("patch-omniroute: OK applied")


if __name__ == "__main__":
    main()
