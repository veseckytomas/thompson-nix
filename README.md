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
3. Add rclone remote configs
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

| Prefix in chains | Provider (catalog id) | Auth |
| ---------------- | --------------------- | ---- |
| `cc/`            | Claude Code (`claude`) | OAuth — sign in with the Anthropic Claude subscription |
| `cx/`            | OpenAI Codex (`codex`) | OAuth — sign in with the OpenAI/ChatGPT subscription |
| `agy/`           | Antigravity CLI (`agy`) | Import the `agy` CLI token, auto-detect a local login, or sign in with Google |

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
echo -n "OMNIROUTE_TOKEN=<paste-token>" | gpg --encrypt --recipient vesecky@proton.me --output ~/.config/api_keys/omniroute_token.gpg
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
sqlite3 ~/.local/share/omniroute/data/storage.sqlite \
  "SELECT timestamp, provider, status, error_summary FROM call_logs WHERE status >= 400 ORDER BY timestamp DESC LIMIT 10;"
```

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
