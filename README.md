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
5. Add the FIT VPN CA certificate — see [VPN setup](#vpn-setup) below.
6. Any subsequent rebuild for both nixos and home-manager can be rebuilt with helper script `nixos-run`.

## VPN setup

`modules/networking/vpn.nix` declares two CTU profiles (`vic-vpn`, `fit-vpn`) through
`networking.networkmanager.ensureProfiles`, so they appear in nm-applet after a rebuild with no
manual import.

**Passwords are saved on the machine, never in this repo.** The profiles carry only non-secret
fields (gateway, realm, CTU login). The password itself goes to **gnome-keyring** via nm-applet the
first time you connect and tick *Save password*; it is stored under `~/.local/share/keyrings/`,
unlocked by the login keyring, and never touches git or the Nix store.

This is driven by NetworkManager's per-secret flags (`man 5 nm-settings`, `NMSettingSecretFlags`):

| Flag value | Name          | Meaning                             | Used for                        |
| ---------- | ------------- | ----------------------------------- | ------------------------------- |
| `1`        | `agent-owned` | secret agent stores it (keyring)    | `fit-vpn` password              |
| `2`        | `not-saved`   | prompt every time, never persisted  | one-shot cookies, OTP challenge |

For the openconnect profile (`vic-vpn`) the equivalent switch is `save_passwords=yes`,
which tells the auth dialog to push the password into the keyring. Its `*-flags=2` entries are
session cookies and cert confirmations — correctly never stored.

| Profile    | Protocol            | Gateway            | Notes                              |
| ---------- | ------------------- | ------------------ | ---------------------------------- |
| `vic-vpn`  | openconnect         | `vpn.is.cvut.cz`   |                                    |
| `fit-vpn`  | openvpn             | `vpn.fit.cvut.cz`  | needs the CA certificate below     |

The only manual step is the FIT CA certificate, which is not in this repo:

```bash
mkdir -p ~/.cert/nm-openvpn
# copy fit-vpn-ca.pem there, then:
chmod 600 ~/.cert/nm-openvpn/fit-vpn-ca.pem
```

### CVUT FortiGate VPN (SAML SSO)

CTU's main VPN is FortiGate with Entra ID SAML SSO, which the NetworkManager openconnect plugin
cannot do, so it lives outside NetworkManager in `modules/networking/fortivpn.nix`. This is the
external-browser SSO flow that CTU's own manual prescribes:
https://ist.cvut.cz/en/support/user-manuals/vpn-fortinet-linux/

Usage:

- `cvut-vpn up | down | toggle | status`; `status` prints exactly one of `connected`,
  `connecting`, `disconnected`.
- `mod+v` opens the rofi menu; the CVUT row shows live status and toggles on select, same as the
  VIC and FIT rows. The qtile bar VPN widget has been removed; rofi is the only control surface.

How it works: the root `cvut-vpn.service` runs `openfortivpn vpn.net.cvut.cz:443 --saml-login=8020`.
`cvut-vpn up` starts the unit, waits for the loopback listener on `127.0.0.1:8020`, then
`xdg-open`s `https://vpn.net.cvut.cz:443/remote/saml/start?redirect=1` in the default browser
(LibreWolf). After Entra ID SSO + MFA the gateway redirects back to
`http://127.0.0.1:8020/?id=<session-id>`; openfortivpn exchanges that id at
`/remote/saml/auth_id` for the `SVPNCOOKIE` and brings up `ppp0`. No cookie ever touches disk,
argv, or the journal. openfortivpn never opens a browser itself (its `print_url()` only logs the
URL), which is why the wrapper calls `xdg-open`.

Why openfortivpn is patched: upstream `src/http_server.c` hardcodes `int max_tries = 5;` with a
10-second `select()` timeout, a 50-second ceiling exposed by no CLI flag or config key and still
unfixed on master. Interactive Entra MFA routinely exceeds it, producing `ERROR: Finally failed to
retrieve SAML authentication token`. The module raises it to `max_tries = 60` (~10 minutes) via
`pkgs.openfortivpn.overrideAttrs` + `substituteInPlace --replace-fail`, so the build fails loudly
if upstream ever moves that literal.

Why not proprietary FortiClient: CTU's download directory (`download.cvut.cz/forticlient/`) is
SSO-login-gated, so there is no reproducible `fetchurl`. The only community NixOS flake has a
single commit, was tested only on NixOS 24.05 (this machine runs 26.11/unstable), pins a `.deb`
its own README says Fortinet will rotate to a 404, and needs `nix-ld` + `/opt/forticlient` + a
root daemon + an autostart GUI tray to broker the SAML deep link.

One-time manual cleanup. **Warning: destructive. Run only AFTER the new flow is verified
working.** `ensureProfiles` is additive and can never remove a profile, so stale ones must be
deleted by hand:

```bash
nmcli -f NAME,UUID,TYPE connection show      # inspect before deleting
nmcli connection delete uuid bfea377e-63f4-4224-a1a9-1a19bc2003ed   # stale legacy cvut-vpn (openconnect, vpn.cvut.cz)
nmcli connection delete uuid 64f618ba-b11f-4a15-b686-5474e7564316   # stale duplicate fit-vpn
```

The surviving fit-vpn must be uuid `8963a4d6-2a94-450c-95dc-c8ac6024d8f6` (the one declared in
`vpn.nix`).

Diagnostics:

```bash
cvut-vpn status                                  # connected | connecting | disconnected
journalctl -u cvut-vpn.service -n 50 --no-pager
ip -brief link show ppp0
ss -ltn 'sport = :8020'                          # listener present while SSO is pending
nc -zv -w5 ldap.cvut.cz 636                      # internal-only; must succeed only while connected
```

A cancelled SSO leaves the unit waiting up to 10 minutes; run `cvut-vpn down` (or toggle in rofi)
to stop it immediately.

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
| `antigravity/`   | Antigravity CLI (`antigravity`) | Import the `agy` CLI token, auto-detect a local login, or sign in with Google |

> `chains.json` uses the canonical provider id `antigravity/`, which is what the resolver reads. `agy` is only a legacy model-prefix alias; the dashboard may still persist the connection under it, so the `omniroute-normalize-providers` service rewrites `agy`→`antigravity` on every gateway start (idempotent, token-free) — otherwise every Antigravity model returns `404 No active credentials for provider: antigravity` and any chain that only falls through to it collapses to `503 ALL_ACCOUNTS_INACTIVE`.

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
journalctl --user -u omniroute-provision.service -f   # expect "26 provisioned, 0 failed"
```

Verify combos and available models:

```bash
TOKEN=$(gpg --decrypt -q ~/.config/api_keys/omniroute_token.gpg | cut -d= -f2)
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:20128/api/combos | jq -r '.combos[].name' | sort
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:20128/v1/models | jq -r '.data[].id' | grep -E '^(cc|cx|antigravity|litellm)/' | sort
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
