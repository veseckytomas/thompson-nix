# OneDrive crypt migration: base32 → base32768

Shortens encrypted filenames so long paths stop hitting OneDrive's path-length limit.
Your visible file and folder names do **not** change — only the ciphertext stored on OneDrive.

## Why

`eOnedrive` is a crypt remote; crypt encrypts filenames too, and encoding them inflates their
length. Measured with `rclone cryptdecode --reverse` on the two paths that currently fail:

| Encoding | PDF path | JSON path |
| --- | --- | --- |
| Plaintext (what you see) | 195 | 119 |
| `base32` (current) | 390 | 372 |
| `base64` | 327 | 313 |
| **`base32768` (target)** | **134** | **134** |

Microsoft's error says the limit is 400 characters, but measured behaviour is stricter: an
encrypted total of 350 uploads fine and 375 fails. Both failing paths sit above that line.
`base32768` cuts them by ~65%, with room to spare.

## This is server-side — no re-upload

`rclone move --server-side-across-configs` between two crypts over the *same* backend is a
**rename on Microsoft's servers**. Nothing is downloaded or re-uploaded. rclone's own crypt
docs name this exact use case ("change file name encryption type without re-uploading all
the data").

Verified on this account, both variants:

```
Server Side Moves:      1 @ 8 B      # move, in place
Server Side Copies:     1 @ 9 B      # copy, into share2
```

Both completed in seconds with zero bytes transferred, and the moved file read back correctly
under base32768. So the work is **not** bandwidth-bound — a fast connection helps far less than
you'd expect. It is bound by per-object API calls: ~24k objects at a few per second.

**You do not need a fast connection for this.** Run it whenever convenient; a work link buys
you almost nothing, because almost nothing crosses the wire.

## Scope

| Metric | Value |
| --- | --- |
| Objects | 23,940 |
| Data | 107.2 GiB |
| OneDrive free | 900.5 GiB (a side-by-side copy fits) |
| Bytes transferred | **0** (server-side) |
| Files failing today | 2 |

## Before you start — confirm the two remotes share a key

`eOnedrive2` already exists and is correctly configured: crypt over `onedrive:share2`,
`filename_encoding = base32768`, with **both** `password` and `password2` identical to
`eOnedrive`. Only the encoding differs, which is exactly what a server-side migration needs.

Verified by a real server-side move between the two remotes (`Server Side Moves: 1`, 0 bytes
transferred), with the file read back correctly afterwards.

If both crypts did *not* share a key, rclone would be forced to decrypt and re-encrypt —
a full 107 GiB round-trip, the thing this migration exists to avoid. So confirm before
starting:

```bash
rclone copyto /etc/hostname eOnedrive:_pre/x.txt
rclone move eOnedrive:_pre eOnedrive2:_pre --server-side-across-configs -v
rclone purge eOnedrive2:_pre
```

**Gate:** the summary says `Server Side Moves: 1`. If it says `Transferred` with real bytes
instead, the keys differ — stop and investigate.

> Note on inspecting the config by hand: obscured values can start with `-`, which
> `rclone reveal` parses as a flag. Always use `rclone reveal -- "$value"`. Without the `--`
> it fails and prints nothing, which is easy to misread as an empty password.

## Runbook

Each step has a gate. Do not continue past a gate that fails.

### 1. Stop the mount

Prevents writes landing in the old remote mid-migration.

```bash
systemctl --user stop rclone-onedrive.service
findmnt -T ~/mnt/Onedrive -o FSTYPE --noheadings   # gate: no fuse.rclone row
```

### 2. Check the VFS cache for unflushed writes

```bash
find ~/.cache/rclone/vfs/eOnedrive -type f
```

Anything listed has not reached OneDrive. The two known `pathIsTooLong` files will appear here —
expected; step 6 is what finally uploads them. Anything *else* listed should be investigated
before you continue.

### 3. Copy server-side into `share2`

Copy, not move — the original stays intact at `onedrive:share` as your rollback.

```bash
tmux new -s migrate
rclone copy eOnedrive: eOnedrive2: \
  --server-side-across-configs \
  --progress --transfers 8 --checkers 16 \
  --log-file ~/migrate-base32768.log --log-level INFO
```

Detach `Ctrl-b d`, reattach `tmux attach -t migrate`. Safe to interrupt; `copy` resumes and
skips what already matched.

**Gate:** the summary must say `Server Side Copies:` with `Transferred: 0 B` (or near it).
If you see real bytes moving, the two crypts are not sharing a key — stop and recheck the
pre-flight gate above, or you are about to push 107 GiB.

### 4. Verify

```bash
rclone check eOnedrive: eOnedrive2: --one-way --log-file ~/migrate-check.log
rclone size eOnedrive:
rclone size eOnedrive2:
```

**Gate:** `0 differences found`, and both `size` outputs agree (23,940 objects / 107.2 GiB,
allowing for anything you have changed since).

### 5. Repoint the mount

In `home-manager/vesecto/modules/rclone.nix`, change the `rclone-onedrive` `ExecStart` remote
from `eOnedrive:` to `eOnedrive2:` (leave every flag as-is), then:

```bash
cd ~/Git/Personal/thompson-nix
alejandra home-manager/vesecto/modules/rclone.nix
home-manager build --flake .#vesecto        # gate: exit 0
nixos-run                                   # home-only rebuild
systemctl --user status rclone-onedrive.service
ls ~/mnt/Onedrive                           # gate: your files, correct names
```

### 6. Confirm the original failure is fixed

```bash
systemctl --user restart rclone-onedrive.service
sleep 60
journalctl --user -u rclone-onedrive.service -n 50 | grep -i pathistoolong \
  || echo "no pathIsTooLong errors"
```

The two previously-stuck files should now upload from the VFS cache on their own.

### 7. Delete the old data (only after several days of normal use)

Irreversible. Keep the old copy as your rollback until you are confident.

```bash
rclone purge onedrive:share
rclone config delete eOnedrive
```

Optionally rename `eOnedrive2` → `eOnedrive` afterwards and revert the `ExecStart` change.

## Rollback

Before step 7, rollback is free: revert `ExecStart` to `eOnedrive:` and rebuild. The original
data is untouched at `onedrive:share` throughout.

## Notes

- OneDrive is case-insensitive: `share` and `Share` are the same folder. `share2` is distinct.
- `base32768` ciphertext uses CJK codepoints — expected, and why it packs more per character.
- The encodings are mutually unreadable: a base32768 remote cannot list base32 data, and vice
  versa. The data is not lost, just invisible under the wrong encoding.
- Do not run both mounts against the same mountpoint simultaneously.
- The `.omo/` scratch directory (opencode session state) syncs into Notes and generates long
  paths. Consider `--exclude '.omo/**'` on the mount regardless of this migration.
