# Repository with NixOS config used by Thompson

This repository contains these configurations:

- NixOS configuration for 3 machines I use
- Home Manager configuration for my user
- ISO configuration for NixOS installation
- ISO configuration for disk rescue

## Configurations present

- Desktop
- Laptop
- 16" Laptop
- Laptops for Tunneling game used during PTMM24
- Install ISO
- Disk rescue ISO
- Home-manager config

## Custom packages

These packages require manual update by changing rev and hash

- ./modules/loginManagers/sddm-theme/sddm-theme.nix
- ./home-manager/vesecto/modules/nvim/plugins/kulala.nix

## Initial setup

1. Run setup script on system with flakes enabled

```bash
./scripts/setup.sh
```

2. Add ssh, gpg keys, certificates.
3. Set thunderbird email accounts and add certificates.
4. Any change line 14 in scripts/home.sh to $USERNAME
5. Any subsequent rebuild for both nixos and home-manager can be rebuilt with helper script `nixos-run`.

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
