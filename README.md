# Repository with NixOS config used by Thompson

This repository contains these configurations:

- NixOS configuration for 3 machines I use
- Home Manager configuration for my user
- ISO configuration for NixOS installation
- ISO configuration for disk rescue

## Configurations present

- Desktop
- Laptop
- Test laptop
- Install ISO
- Disk rescue ISO
- Home-manager config

## Custom packages

These packages require manual update by changing rev and hash

- ./modules/loginManagers/sddm-theme/sddm-theme.nix

## Initial setup

1. Run setup script on system with flakes enabled

```bash
./scripts/setup.sh
```

2. Add Yubikeys

```bash
nix shell nixpkgs#pam_u2f
mkdir -p ~/.config/Yubico
# Insert Yubikey
pamu2fcfg > ~/.config/Yubico/u2f_keys
# Insert second Yubikey
pamu2fcfg -n >> ~/.config/Yubico/u2f_keys
```

3. Add ssh, gpg keys, certificates.
4. Set thunderbird email accounts and add certificates.
5. Any change line 14 in scripts/home.sh to $USERNAME
6. Configure VPN
   - Faculty
   - University
   - Home
7. Any subsequent rebuild for both nixos and home-manager can be rebuilt with helper script `nixos-run`.

## TMUX

1. Install plugins with `<leader>I`
2. Plugins can be update with `<leader>U`

## Neovim initial setup

- Authenticate to plugins by running these commands in neovim

```vimscript
Codeium Auth
Copilot auth
WakaTimeApiKey
```

## ZSH

- Plugins can be updated by running `zinit update`
