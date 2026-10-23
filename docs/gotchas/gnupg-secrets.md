<!--
  ________
 /_  __/ /_  ____  ____ ___  ____  _________  ____
  / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
 / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
/_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
                         /_/
Tomáš Vesecký
Email: vesecky@proton.me
GitHub: veseckytomas
GitLab: vesecky.tomas
-->

# GnuPG and secrets gotchas

## Decrypting

**Never call `gpg --decrypt` directly — use `gpg-decrypt-hardened`** (`home-manager/vesecto/modules/gnupg/`). A keyboxd that dies by SIGKILL leaves a dotlock naming a PID the kernel later recycles, and GnuPG only clears a lock whose PID is *dead*, so a recycled PID wedges every decrypt for 10s and then lies with `No secret key`. The wrapper classifies by liveness (`/proc/<pid>/comm != keyboxd`), not by link count. Default `--pinentry error`; use `--pinentry ask` only for Yubikey-gated blobs.

## `~/.gnupg/common.conf`

**`~/.gnupg/common.conf` is home-manager-managed** (`gnupg/common-conf.nix`). Editing it by hand is reverted on the next switch, and a pre-existing unmanaged copy blocks activation — move it aside first.

## Where secrets live

Secrets are GPG-encrypted blobs committed as ciphertext in `home-manager/vesecto/modules/api_keys/*.gpg`, decrypted only at consume time — there is no git-crypt in this repo. SSH/GPG keys and rclone/thunderbird configs are added manually post-install (see `README.md`).
