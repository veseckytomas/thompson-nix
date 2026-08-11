# OneDrive crypt migration: base32 → base32768

Shortens encrypted filenames so long paths stop hitting OneDrive's 400-character URL limit.
Your visible file and folder names do **not** change — only the ciphertext stored on OneDrive.

## Why

`eOnedrive` is a crypt remote; crypt encrypts filenames too. The default `base32` encoding
roughly doubles them. Measured on the failing path:

| | Length |
| --- | --- |
| Plaintext path | 195 |
| Encrypted, `base32` (current) | 391 (+`share/` = ~397, limit is 400) |
| Encrypted, `base32768` (new) | **141** |

## Scope

| Metric | Value |
| --- | --- |
| Data to re-encrypt | 94.9 GiB |
| Files | 19,729 |
| OneDrive free space | 912 GiB (side-by-side copy fits) |
| Files broken today | 0 |
| Files within 50 chars of the limit | 1,886 |

Nothing is broken right now; this is preventive. The one file that fails to upload
(`priloha_…_MP.pdf`) exists only in the local VFS cache, never on the remote.

## Already done

- `eOnedrive2` remote created: crypt over `onedrive:share2`, `filename_encoding = base32768`
- Both passwords verified byte-identical to `eOnedrive` (same keys, only encoding differs)
- Round-trip proven: the failing path was written, read back, and measured at 141 chars
- Test data purged; `onedrive:share2` is a clean slate

## Runbook

Each step has a gate. Do not continue past a gate that fails.

### 1. Stop the mount

Prevents writes landing in the old remote mid-copy.

```bash
systemctl --user stop rclone-onedrive.service
findmnt -T ~/mnt/Onedrive -o FSTYPE --noheadings   # expect: no fuse.rclone row
```

### 2. Flush anything pending in the VFS cache

```bash
ls -la ~/.cache/rclone/vfs/eOnedrive/
```

Anything still here has not reached OneDrive. The known `pathIsTooLong` PDF will be here —
that is expected, and step 6 is what finally uploads it.

### 3. Copy (the long part — run in tmux)

Roughly 3 hours at 10 MB/s; longer on a slower link. It saturates your uplink.

```bash
tmux new -s migrate
rclone copy eOnedrive: eOnedrive2: \
  --progress --transfers 8 --checkers 16 \
  --log-file ~/migrate-base32768.log --log-level INFO
```

Detach with `Ctrl-b d`, reattach with `tmux attach -t migrate`.
Safe to interrupt: `rclone copy` resumes and skips what already matched.

### 4. Verify (gate — do not skip)

```bash
rclone check eOnedrive: eOnedrive2: --one-way --log-file ~/migrate-check.log
rclone size eOnedrive:
rclone size eOnedrive2:
```

**Gate:** `check` reports `0 differences found`, and both `size` outputs show
19,729 objects / 94.9 GiB. If counts differ, re-run step 3 — do not proceed.

### 5. Repoint the mount

In `home-manager/vesecto/modules/rclone.nix`, change the `rclone-onedrive` `ExecStart`
remote from `eOnedrive:` to `eOnedrive2:` (leave every flag as-is), then:

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
cp "<the PDF>" "$HOME/mnt/Onedrive/Documents/DatovaSchranka/OSVC/2026-08-07_OSSZ Mladá Boleslav (Územní správa sociálního zabezpečení pro hlavní město Prahu a Středo/"
sleep 30
rclone lsl "eOnedrive2:Documents/DatovaSchranka/OSVC/" | grep Upozorneni
journalctl --user -u rclone-onedrive.service -n 20 | grep -i pathistoolong || echo "no pathIsTooLong errors"
```

### 7. Delete the old data (only after several days of normal use)

Irreversible. Keep the old copy as your rollback until you are confident.

```bash
rclone purge onedrive:share
rclone config delete eOnedrive
```

Optionally rename `eOnedrive2` → `eOnedrive` afterwards and revert the `ExecStart` change.

## Rollback

Before step 7, rollback is free: revert `ExecStart` to `eOnedrive:` and rebuild.
The original data is untouched at `onedrive:share` throughout.

## Notes

- OneDrive is case-insensitive: `share` and `Share` are the same folder. `share2` is distinct.
- `base32768` ciphertext is CJK codepoints — expected, and why it packs more per character.
- Do not run both mounts against the same mountpoint simultaneously.
