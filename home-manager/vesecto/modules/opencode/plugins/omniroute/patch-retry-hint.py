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
# Caps the combo Retry-After hint: one skipped member's far-future rate_limited_until (weekly plan reset) otherwise parks clients ~1 day while later chain members recover in minutes.
import sys
from pathlib import Path

TARGET = "open-sse/services/combo/comboAttemptLoop.ts"
ANCHOR = "    return getEarliestRateLimitedUntil(accounts);\n"
MARKER = "retryHintCapMs"
REPLACEMENT = (
    "    const retryHint = getEarliestRateLimitedUntil(accounts);\n"
    "    if (!retryHint) return null;\n"
    "    const retryHintCapMs = Date.now() + 120_000;\n"
    "    return new Date(Math.min(Date.parse(retryHint), retryHintCapMs)).toISOString();\n"
)


def die(msg):
    print(f"patch-retry-hint: FATAL {msg}", file=sys.stderr)
    sys.exit(1)


def main():
    if len(sys.argv) != 2:
        die("usage: patch-retry-hint.py <omniroute package root>")
    path = Path(sys.argv[1]) / TARGET
    if not path.is_file():
        die(f"{TARGET} vanished upstream - the retry-hint clamp has no anchor")
    text = path.read_text()
    if MARKER in text:
        print("patch-retry-hint: OK already applied")
        return
    if text.count(ANCHOR) != 1:
        die(f"anchor not unique in {TARGET} ({text.count(ANCHOR)} hits) - upstream drifted, re-derive the clamp")
    path.write_text(text.replace(ANCHOR, REPLACEMENT, 1))
    print("patch-retry-hint: OK applied")


if __name__ == "__main__":
    main()
