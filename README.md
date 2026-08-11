# Repository with NixOS config used by Thompson

This repository contains these configurations:

- NixOS configuration for machines I use
- Home Manager configuration for my user
- ISO configuration for NixOS installation
- ISO configuration for disk rescue

## Configurations present

- Desktop
- Laptop
- Servers
- Install ISO
- Disk rescue ISO
- Home-manager config as Standalone
- Server Home-manager config as NixOS module

## Initial setup

1. Run setup script on system with flakes enabled

```bash
./scripts/setup.sh
```

1. Add ssh, gpg keys, certificates.
2. Set thunderbird email accounts and add certificates.
3. Add rclone remote configs (`onedrive`, `eOnedrive`, `Dropbox`, `ProtonDrive` — see [ProtonDrive rclone setup](#protondrive-rclone-setup) below).
4. Connect opencode providers (OpenAI, Anthropic, LiteLLM) — see [OmniRoute setup](#omniroute-setup) below.
5. Any subsequent rebuild for both nixos and home-manager can be rebuilt with helper script `nixos-run`.

## OmniRoute setup

OmniRoute is a local AI gateway that fronts multiple providers behind one endpoint and routes each opencode agent through a named **chain** (combo) with priority fallback. The gateway runs as a Home Manager user service on `127.0.0.1:20128`; opencode talks to it via the `omniroute` provider (`omniroute/<chain-name>`).

The Nix config (`home-manager/vesecto/modules/opencode/plugins/omniroute/`) installs the gateway, defines the chains in `chains.json`, and auto-provisions them on every rebuild. Everything below is the **manual, per-machine** setup the Nix config cannot do (OAuth sign-ins, API keys, secrets).

### 1. Confirm the gateway is running

```bash
systemctl --user status omniroute.service
curl -s http://localhost:20128/api/monitoring/health | jq '.status'   # "healthy"
```

If `setupComplete` is false, open the UI (step 6) and finish the first-run setup wizard (creates the admin account).

### 2. Authenticate the providers (UI → Providers)

Open the UI, go to **Providers**, and connect each. The provider id must match the model prefix used in `chains.json`.

| Prefix in chains | Provider (catalog id)   | Auth                                                                          |
| ---------------- | ----------------------- | ----------------------------------------------------------------------------- |
| `cc/`            | Claude Code (`claude`)        | OAuth — sign in with the Anthropic Claude subscription                        |
| `cx/`            | OpenAI Codex (`codex`)        | OAuth — sign in with the OpenAI/ChatGPT subscription                          |
| `agy/`           | Antigravity CLI (`antigravity`) | Import the `agy` CLI token, auto-detect a local login, or sign in with Google |

> `agy/` is only the model-prefix **alias**; the resolver reads the canonical provider id `antigravity`. The dashboard persists the connection under `agy`, so the `omniroute-normalize-providers` service rewrites it to `antigravity` on every gateway start (idempotent, token-free) — otherwise every `agy/*` model returns `404 No active credentials for provider: antigravity` and any chain that only falls through to `agy` (e.g. `quick-chain`) collapses to `503 ALL_ACCOUNTS_INACTIVE`.

For LiteLLM (`litellm/` prefix) — register a **custom OpenAI-compatible provider**:

- Name: `litellm` (must match the prefix)
- Base URL: `https://llm.ai.e-infra.cz/v1`
- API key: the e-infra LiteLLM key

Models are discovered automatically after each connection is added (OAuth providers ship a built-in catalog; LiteLLM resolves models live from its `/models` endpoint).

### 3. Create a management API key

The provision script needs a key with **`manage`** (or `admin`) scope to write combos — a `self:usage` key is rejected with `Invalid management token`.

UI → **Admin → API Keys → Create** → set scope to `manage` → copy the token.

### 4. Store the token (GPG, outside the repo)

The token lives outside git, decrypted at service start. One file per machine (each machine's OmniRoute instance issues its own key):

```bash
echo -n "OMNIROUTE_TOKEN=<paste-token>" | gpg --encrypt --recipient <gpg-key> --output ~/.config/api_keys/omniroute_token.gpg
gpg --decrypt -q ~/.config/api_keys/omniroute_token.gpg   # verify → OMNIROUTE_TOKEN=<token>
```

### 5. Provision the chains

```bash
nixos-run                                       # home-only rebuild
systemctl --user restart omniroute.service      # provision runs after the gateway (Yubikey touch to decrypt)
journalctl --user -u omniroute-provision.service -f   # expect "22 provisioned, 0 failed"
```

Verify combos and available models:

```bash
TOKEN=$(gpg --decrypt -q ~/.config/api_keys/omniroute_token.gpg | cut -d= -f2)
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:20128/api/combos | jq -r '.combos[].name' | sort
curl -s http://localhost:20128/v1/models | jq -r '.data[].id' | grep -E '^(cc|cx|agy|litellm)/' | sort
```

### 6. Open the web UI at `http://omniroute`

The `modules/networking/omniroute-proxy.nix` NixOS module adds a `127.0.0.1 omniroute` hosts entry and a Caddy reverse proxy bound to localhost (`http://omniroute` → `127.0.0.1:20128`, no exposed port). Requires a **system** rebuild, not home-only.

If the browser shows a DNS error (e.g. `wasn't found by dns10.quad9.net`), it is using DNS-over-HTTPS and bypassing `/etc/hosts`. In LibreWolf/Firefox `about:config`, exclude the name from DoH:

```
network.trr.excluded-domains = omniroute
```

### Diagnostics

```bash
omniroute logs --lines 30 --filter error        # recent errors
omniroute providers test-all                    # test every connection
omniroute health                                 # circuit breakers, lockouts
journalctl --user -u omniroute-normalize-providers.service   # agy→antigravity key normalization
sqlite3 ~/.local/share/omniroute/data/storage.sqlite \
  "SELECT timestamp, provider, status, error_summary FROM call_logs WHERE status >= 400 ORDER BY timestamp DESC LIMIT 10;"
```

## ProtonDrive rclone setup

`home-manager/vesecto/modules/rclone.nix` declares the `rclone-protondrive` user service that mounts `ProtonDrive:` at `~/mnt/ProtonDrive`. The remote itself is **manual** — credentials never live in this repo.

Unlike `eOnedrive` (an rclone `crypt` remote layered over `onedrive:share`), ProtonDrive is mounted **directly**: Proton is already end-to-end encrypted, and a crypt layer would make the files unreadable in Proton's own web and mobile apps.

### 1. Create the remote

```bash
rclone config
```

- `n` → new remote, name it **`ProtonDrive`** (capitalised — must match the service's mount command exactly)
- storage → `protondrive` (the backend type is lowercase, unlike the remote name)
- `username` → the Proton account email
- `password` → choose `y) Yes type in my own password` and type it at the hidden prompt; rclone obscures it automatically

Never pass `password=` on the command line — it lands in shell history.

### 2. Handle 2FA (advanced config)

Answer `y` to `Edit advanced config?`, then either:

- **Recommended (unattended):** set `otp_secret_key` to the TOTP *seed* (the base32 string behind the QR code, Proton → Account → Security → 2FA). rclone can then regenerate codes itself if the cached session ever fully expires.
- **Minimum secret at rest:** leave `otp_secret_key` empty and type the current 6-digit code when prompted at first authentication.

Leave `mailbox_password` empty unless a separate mailbox password is in use, and leave `enable_caching` at its default — the mount overrides it on the command line.

Do not leave a `2fa = <6 digits>` line in the config; a one-shot code is stale within 30 seconds and breaks later re-auth. Clear it if the wizard wrote one:

```bash
rclone config update ProtonDrive 2fa ""
```

`rclone config update` does **not** obscure values — only the interactive wizard does. Any field the docs mark "must be obscured" (`password`, `otp_secret_key`, `mailbox_password`) has to be wrapped explicitly, or auth fails with `422 .../auth/v4/2fa Incorrect login credentials`:

```bash
rclone config update ProtonDrive otp_secret_key "$(rclone obscure '<TOTP-seed>')"
```

Check the round-trip before spending an auth attempt — reveal must return the original base32 seed:

```bash
rclone reveal "$(awk '/^\[ProtonDrive\]/{f=1;next} /^\[/{f=0} f' ~/.config/rclone/rclone.conf | awk -F'= *' '/^otp_secret_key/{print $2}')" \
  | grep -qE '^[A-Z2-7]+=*$' && echo "valid base32 seed" || echo "wrong - not obscured, or not a seed"
```

### 3. Verify before rebuilding

```bash
rclone about ProtonDrive:                                   # exits 0 and prints quota (works even on an empty drive)
awk '/^\[ProtonDrive\]/{f=1;next} /^\[/{f=0} f' ~/.config/rclone/rclone.conf | grep -c '^client_'
```

`rclone lsd ProtonDrive:` printing nothing is not an error — it means the drive has no top-level folders yet. Use `rclone about` to prove authentication.

The second command must print **`4`**. Those cached keys (`client_uid`, `client_access_token`, `client_refresh_token`, `client_salted_key_pass`) are written back by rclone after a successful login and are what let the service start on every boot **without** a TOTP prompt. If it prints `0`, the mount will fail at boot — re-run `rclone lsd ProtonDrive:` and confirm `rclone.conf` is writable.

### 4. Activate and check

```bash
nixos-run                                                   # home-only rebuild
systemctl --user status rclone-protondrive.service          # active (running)
findmnt -T ~/mnt/ProtonDrive -o TARGET,FSTYPE --noheadings  # fuse.rclone
```

### Diagnostics

```bash
journalctl --user -u rclone-protondrive.service -n 30
systemctl --user restart rclone-protondrive.service   # ExecStartPre clears a stale FUSE endpoint
```

The mount omits `--poll-interval` because the protondrive backend has no ChangeNotify/event system, and it passes `--protondrive-enable-caching=false` because that backend cache never invalidates under VFS. Changes made from Proton's web or mobile app therefore appear within `--dir-cache-time` (5m), not instantly. `--allow-other` must **not** be added — `user_allow_other` is disabled in `/etc/fuse.conf`, so it would fail the mount at startup.

## Neovim initial setup

- Authenticate to plugins by running these commands in neovim

```vimscript
Codeium Auth
Copilot auth
WakaTimeApiKey
```

## TODO

### TomasVesa-NTB-NixOS

- High resolution scaling
- Touchscreen
- Speaker

## Acknowledgments

I would like to thank to all that projects that I used in my configuration.

| Repository                                                | License     | Functionality                           |
| --------------------------------------------------------- | ----------- | --------------------------------------- |
| [ZaneyOS](https://gitlab.com/Zaney/zaneyos)               | MIT License | Hyprland config and other small changes |
| [DT dotfiles](https://gitlab.com/dwt1/dotfiles)           | No License  | Qtile config                            |
| [Loqusion dotfiles](https://github.com/loqusion/dotfiles) | No License  | Rofi theme                              |
