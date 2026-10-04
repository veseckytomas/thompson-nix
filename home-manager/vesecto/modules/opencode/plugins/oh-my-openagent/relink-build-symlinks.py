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
# bun's hoisted linker points nested workspace members at absolute build-dir paths, which cp -R copies verbatim and fixupPhase then rejects as dangling.
import os
import sys

BUILD_PREFIX = "/build/source/"


def die(msg):
    print(f"relink-build-symlinks: FATAL {msg}", file=sys.stderr)
    sys.exit(1)


def main():
    if len(sys.argv) != 2:
        die("usage: relink-build-symlinks.py <out>")
    out = os.path.realpath(sys.argv[1])
    relinked = 0
    stale = []
    for root, dirs, files in os.walk(out, followlinks=False):
        for name in dirs + files:
            path = os.path.join(root, name)
            if not os.path.islink(path):
                continue
            target = os.readlink(path)
            if not target.startswith(BUILD_PREFIX):
                continue
            rewritten = os.path.join(out, target[len(BUILD_PREFIX) :])
            if not os.path.exists(rewritten):
                stale.append(f"{path} -> {target}")
                continue
            os.unlink(path)
            os.symlink(os.path.relpath(rewritten, os.path.dirname(path)), path)
            relinked += 1
    if stale:
        die(f"{len(stale)} build-dir symlink(s) have no counterpart in $out: {stale[:3]}")
    # A no-op means bun stopped emitting them and this step should go, not idle.
    if relinked == 0:
        die("no build-dir symlinks found; bun's linker changed and this step is dead code")
    print(f"relink-build-symlinks: OK {relinked} symlink(s) re-pointed into $out")


if __name__ == "__main__":
    main()
