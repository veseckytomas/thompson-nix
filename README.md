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

## Initial setup

1. run rebuild on system with flakes enabled

```bash
sudo nixos-rebuild switch --flake .#$HOSTNAME
```

2. run home-manager rebuild

```bash
home-manager switch --flake .#$USERNAME
```

3. Add Yubikeys

```bash
nix shell nixpkgs#pam_u2f
mkdir -p ~/.config/Yubico
# Insert Yubikey
pamu2fcfg > ~/.config/Yubico/u2f_keys
# Insert second Yubikey
pamu2fcfg -n >> ~/.config/Yubico/u2f_keys
```

4. Add ssh, gpg keys, certificates.
5. Set thunderbird email accounts and add certificates.
6. any change line 14 in scripts/home.sh to $USERNAME
7. any subsequent rebuild for both nixos and home-manager can be rebuilt with helper script `nixos-run`.

## TMUX initial setup

1. clone TMP git repository

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

2. install plugins with `<leader>I`
3. plugins can be update with `<leader>U`

## Neovim initial setup

- Authenticate to plugins by running these commands in neovim

```vimscript
Codeium Auth
Copilot auth
WakaTimeApiKey
```

## ZSH initial setup

- plugins can be updated by running `zinit update`
